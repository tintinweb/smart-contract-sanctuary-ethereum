// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";

/*
    ERROR CODES

    Global errors

    EROP1 : Cannot set zero as target

    Owner errors

    EROW1: Caller is not contract owner
    EROW2 : Error while sending fund to target
    EROW3 : Invalid drain amount
    EROW4 : Caller is not external minting contract
    ERLO1 : Lock is not disengaged by other owner
    ERLO2 : Lock was not disengaged recently
    ERLO3 : Lock target is not set
    ERLO4 : Unlocked target not corresponding to given target

    Land handling errors

    ERLT1 : Invalid token id
    ERLT2 : Public sale not open for this zone
    ERLT3 : Value sent does not correspond to price
    ERLT4 : Land already minted
    ERLT5 : No flash sales open for this zone
    ERLT6 : *REMOVED*
    ERLT7 : Land reserved to Terminal18
    ERLT8 : Sender not verified on kyc
    ERLT9 : Batch minting : targets and tokens length mismatch

    Zone handling errors

    ERZ1: Invalid zone number
    ERZ2: Invalid zone flash sale count

*/

contract LandTerminal18 is ERC721 {

    using Strings for uint256;

    struct ZoneInfo {
        uint8 number;
        uint32 start;
        uint32 end;
        uint32 price;
        bool public_sale;
    }

    struct ZoneFlashSale {
        uint8 zone;
        uint16 count;
        uint32 price;
    }

    string private URI = "";

    address private owner_1;
    address private owner_2;
    address private owner_3;
    address private safe_guard;

    address public kyc_contract = address(0);
    address public external_mint_contract = address(0);

    uint32 private safeguard_timeout;

    uint private constant total_land_count = 9731;
    uint private constant reserved_lands = 128;

    uint8 private zone_count = 4;
    ZoneInfo[4] private zone_info_list;
    ZoneFlashSale[4] private flash_sale_list;

    uint constant eth_decimals =   1000000000000000000;
    uint constant price_decimals =     100000000000000;

    uint32 private unlock_timeout;

    uint private unlock_time = 0;
    uint private last_unlock_time = block.timestamp;
    uint8 private unlock_action = 0;
    uint8 private unlock_key = 0;
    address private unlocker_1 = address(0);
    address private unlocker_2 = address(0);
    address private unlock_target = address(0);

    constructor(address owner_1_addr, address owner_2_addr, address owner_3_addr, address safeguard_addr, uint32 unlock_timeout_value, uint32 safeguard_timeout_value) ERC721("LandTerminal18", "LT18") {
        owner_1 = owner_1_addr;
        owner_2 = owner_2_addr;
        owner_3 = owner_3_addr;
        safe_guard = safeguard_addr;
        unlock_timeout = unlock_timeout_value;
        safeguard_timeout = safeguard_timeout_value;
        _initZones();
    }

    function owner() public view returns (address) {
        return owner_1;
    }

    function kycVerified() internal {
        if(kyc_contract != address(0)){
            (bool success,) = kyc_contract.call(abi.encodeWithSignature('isVerified(address)', msg.sender));
            require(success, 'ERLT8');
        }
    }

    // LANDS MINTING

    function _initZones() internal {
        zone_info_list[0] = ZoneInfo(1, 1, 664, 12500, false);
        zone_info_list[1] = ZoneInfo(2, 665, 2564, 5800, false);
        zone_info_list[2] = ZoneInfo(3, 2565, 5457, 2900, false);
        zone_info_list[3] = ZoneInfo(4, 5458, 9731, 1900, false);
        flash_sale_list[0] = ZoneFlashSale(1, 11, 7500);
        flash_sale_list[1] = ZoneFlashSale(2, 38, 3500);
        flash_sale_list[2] = ZoneFlashSale(3, 29, 1700);
        flash_sale_list[3] = ZoneFlashSale(4, 21, 1200);
    }

    function externalMint(address to, uint256 tokenId) public {
        require(msg.sender == external_mint_contract, 'EROW4');
        checkValidTokenId(tokenId, false);
        _safeMint(to, tokenId);
    }

    function mintLand(address to, uint256 tokenId, uint8 lock_key) external {
        onlyOwner();
        if(lockDisengaged(1, lock_key, to, true) && to != address(0)){
            checkValidTokenId(tokenId, true);
            _safeMint(to, tokenId);
        }
    }

    function mintLandBatch(address[] memory targets, uint256[] memory tokenIds, uint8 lock_key) external {
        onlyOwner();
        if(lockDisengaged(2, lock_key, address(0), true)){
            require(targets.length == tokenIds.length, 'ERLT9');
            for(uint i = 0; i < tokenIds.length; i++){
                require(targets[i] != address(0), 'EROP1');
                checkValidTokenId(tokenIds[i], true);
                _safeMint(targets[i], tokenIds[i]);
            }
        }
    }

    function buyLand(uint256 tokenId) payable external {
        checkValidTokenId(tokenId, false);
        kycVerified();
        ZoneInfo memory land_zone = getZone(tokenId);
        require(land_zone.public_sale == true, "ERLT2");
        uint256 price = uint256(land_zone.price) * price_decimals;
        require(msg.value == price, "ERLT3");
        _safeMint(msg.sender, tokenId);
    }

    function buyLandBatch(uint256[] memory tokenIds) payable external {
        kycVerified();
        uint256 totalPrice = 0;
        for(uint i = 0; i < tokenIds.length; i++){
            checkValidTokenId(tokenIds[i], false);
            require(!_exists(tokenIds[i]), "ERLT4");
            ZoneInfo memory land_zone = getZone(tokenIds[i]);
            require(land_zone.public_sale == true, "ERLT2");
            totalPrice += uint256(land_zone.price) * price_decimals;
        }
        require(msg.value == totalPrice, "ERLT3");
        for(uint i = 0; i < tokenIds.length; i++){
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    function buyFlashSaleLand(uint256 tokenId) payable external {
        kycVerified();
        checkValidTokenId(tokenId, false);
        ZoneInfo memory land_zone = getZone(tokenId);
        require(flash_sale_list[land_zone.number - 1].count > 0, "ERLT5");
        uint256 price = uint256(flash_sale_list[land_zone.number - 1].price) * price_decimals;
        require(msg.value == price, "ERLT3");
        _safeMint(msg.sender, tokenId);
        flash_sale_list[land_zone.number - 1].count = flash_sale_list[land_zone.number - 1].count - 1;
    }

    // LANDS COORDINATES

    function getZone(uint256 tokenId) public view returns (ZoneInfo memory) {
        uint index = 0;
        while(index < zone_count && tokenId > zone_info_list[index].end){
            index++;
        }
        return zone_info_list[index];
    }

    // LAND HANDLING

    function checkValidTokenId(uint256 tokenId, bool allow_reserved_lands) internal pure {
        require(tokenId != 0 && tokenId <= total_land_count, "ERLT1");
        require(allow_reserved_lands || tokenId > reserved_lands, "ERLT7");
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    // ZONES HANDLING

    function getZonesData() external view returns (ZoneInfo[] memory) {
        ZoneInfo[] memory infoList = new ZoneInfo[](zone_count);
        for( uint i = 0; i < zone_count; i++){
            infoList[i] = zone_info_list[i];
        }
        return infoList;
    }

    function getFlashSales() external view returns (ZoneFlashSale[] memory) {
        ZoneFlashSale[] memory infoList = new ZoneFlashSale[](zone_count);
        for( uint i = 0; i < zone_count; i++){
            infoList[i] = flash_sale_list[i];
        }
        return infoList;
    }

    function setZonePrice(uint zone, uint price, uint8 lock_key) external {
        onlyOwner();
        if(lockDisengaged(3, lock_key, address(0), true)){
            require(zone >= 1 && zone <= 4, "ERZ1");
            zone_info_list[zone - 1].price = uint32(price);
        }
    }

    function toggleZonePublicSale(uint zone, bool enable, uint8 lock_key) external {
        onlyOwner();
        if(lockDisengaged(4, lock_key, address(0), false)){
            require(zone >= 1 && zone <= 4, "ERZ1");
            zone_info_list[zone - 1].public_sale = enable;
        }
    }

    function toggleZoneFlashSale(uint zone, uint count, uint price, uint8 lock_key) external {
        onlyOwner();
        if(lockDisengaged(5, lock_key, address(0), true)){
            require(zone >= 1 && zone <= 4, "ERZ1");
            require(count <= 1000, "ERZ2");
            flash_sale_list[zone - 1].count = uint16(count);
            flash_sale_list[zone - 1].price = uint32(price);
        }
    }

    // METADATA

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return bytes(URI).length > 0 ? string(abi.encodePacked(URI, tokenId.toString())) : "";
    }

    function setTokenURI(string memory uri) external {
        onlyOwner();
        URI = uri;
    }

    // OWNERS FUNCTIONS

    function onlyOwner() private view {
        require(msg.sender == owner_1 || msg.sender == owner_2 || msg.sender == owner_3 || (msg.sender == safe_guard && uint32(block.timestamp - last_unlock_time) > safeguard_timeout), "EROW1");
    }

    function lockDisengaged(uint8 action, uint8 key, address target, bool strong) private returns (bool) {
        bool check = false;
        if(action == unlock_action && key == unlock_key && target == unlock_target && uint32(block.timestamp - unlock_time) < unlock_timeout){
            if(strong){
                if(unlocker_1 != address(0) && unlocker_2 != address(0) && msg.sender != unlocker_1 && msg.sender != unlocker_2){
                    check = true;
                    last_unlock_time = block.timestamp;
                }
            }else if(unlocker_1 != address(0) && msg.sender != unlocker_1){
                check = true;
            }
        }
        _engageLock();
        return check;
    }

    function _engageLock() internal {
        unlocker_1 = address(0);
        unlocker_2 = address(0);
        unlock_action = 0;
        unlock_key = 0;
        unlock_target = address(0);
    }

    function disengageLock(uint8 action, uint8 key, address target) external {
        onlyOwner();
        if(action == 0 || key == 0){
            _engageLock();
        }else if(unlocker_1 == address(0)){
            unlock_action = action;
            unlock_key = key;
            unlocker_1 = msg.sender;
            unlock_time = block.timestamp;
            unlock_target = target;
        }else if(unlock_action == action && unlock_key == key && unlock_target == target && uint32(block.timestamp - unlock_time) < unlock_timeout && unlocker_1 != msg.sender && unlocker_2 == address(0)){
            unlocker_2 = msg.sender;
            unlock_time = block.timestamp;
        }else{
            _engageLock();
        }
    }

    function drain(address target, uint256 amount, uint8 lock_key) external {
        onlyOwner();
        if(lockDisengaged(7, lock_key, target, true) && target != address(0)){
            require(amount <= address(this).balance, 'EROW3');
            require(payable (target).send(amount), 'EROW2');
        }
    }

    function transferOwnership(address target, uint8 lock_key) external {
        onlyOwner();
        if(lockDisengaged(8, lock_key, target, true) && target != address(0)){
            if(msg.sender == owner_1){
                owner_1 = target;
            }else if(msg.sender == owner_2){
                owner_2 = target;
            }else{
                owner_3 = target;
            }
        }
    }

    function setKycContractAddress(address target, uint8 lock_key) external {
        onlyOwner();
        if(lockDisengaged(9, lock_key, target, true) && target != address(0)){
            kyc_contract = target;
        }
    }

    function setExternalMintContractAddress(address target, uint8 lock_key) external {
        onlyOwner();
        if(lockDisengaged(10, lock_key, target, true) && target != address(0)){
            external_mint_contract = target;
        }
    }

}
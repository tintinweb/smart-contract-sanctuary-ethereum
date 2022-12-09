// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract LandsalePayment is AccessControl, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant admin_role = keccak256("ADMIN_ROLE");
    bytes32 public constant minter_role = keccak256("MINTER_ROLE");
    bytes32 public constant price_updater_role = keccak256("PRICE_UPDATER_ROLE");

    IERC20 private TVK;
    IERC721 private NFT;

    uint256 private totalSupply;
    uint256 private cappedSupply;
    uint256 private slotCount;
    uint256 private TVKperUSDprice;
    uint256 private ETHperUSDprice;

    address private signatureAddress;
    address payable private withdrawAddress;

    bool private ethPaymentEnabled;
    bool private tvkPaymentEnabled;

    mapping(string => categoryDetail) private landCategory;
    mapping(uint256 => slotDetails) private slot;
    mapping(bytes => bool) private signatures;

    struct categoryDetail {
        uint256 priceInUSD;
        uint256 mintedCategorySupply;
        uint256 maxCategorySupply;
        uint256 startRange;
        uint256 endRange;
        bool status;
        bool slotIndependent;
    }

    struct slotDetails {
        uint256 startTime;
        uint256 endTime;
        mapping(string => slotCategoryDetails) slotSupply;
    }

    struct slotCategoryDetails {
        uint256 maxSlotCategorySupply;
        uint256 mintedSlotCategorySupply;
    }

    event landBoughtWithTVK(
        uint256 indexed tokenId,
        uint256 indexed price,
        address indexed beneficiary,
        string category,
        uint256 slot,
        bytes signature
    );

    event landBoughtWithETH(
        uint256 indexed tokenId,
        uint256 indexed price,
        address indexed beneficiary,
        string category,
        uint256 slot,
        bytes signature
    );

    event adminMintedItem(
        string category,
        uint256[] tokenId,
        address[] beneficiary
    );
    event newLandCategoryAdded(
        string indexed category,
        uint256 indexed price,
        uint256 indexed maxCategorySupply
    );
    event newSlotAdded(
        uint256 indexed slot,
        uint256 indexed startTime,
        uint256 indexed endTime,
        string[] category,
        uint256[] slotSupply
    );
    event TVKperUSDpriceUpdated(uint256 indexed price);
    event ETHperUSDpriceUpdated(uint256 indexed price);
    event landCategoryPriceUpdated(
        string indexed category,
        uint256 indexed price
    );
    event categoryAvailabilityInSlotUpdated(
        string indexed category,
        uint256 indexed slot,
        uint256 indexed slotSupply
    );
    event slotStartTimeUpdated(uint256 indexed slot, uint256 indexed startTime);
    event slotEndTimeUpdated(uint256 indexed slot, uint256 indexed endTime);
    event signatureAddressUpdated(address indexed newAddress);
    event TVKAddressUpdated(address indexed newAddress);
    event NFTAddressUpdated(address indexed newAddress);
    event withdrawAddressUpdated(address indexed newAddress);
    event ETHFundsWithdrawn(uint256 indexed amount);
    event TVKFundsWithdrawn(uint256 indexed amount);

    constructor(
        address _TVKaddress,
        address _NFTaddress,
        address payable _withdrawAddress,
        string[] memory _category,
        bool[] memory _slotDependency,
        uint256[][] memory _categoryDetail,
        uint256[][] memory _slot,
        uint256[][] memory _slotSupply
    ) {
        TVK = IERC20(_TVKaddress);
        NFT = IERC721(_NFTaddress);
        signatureAddress = 0x23Fb1484a426fe01F8883a8E27f61c1a7F35dA37;
        withdrawAddress = _withdrawAddress;
        TVKperUSDprice = 28391167192429020000;
        ETHperUSDprice = 805873203910096;
        cappedSupply = 6002;
        totalSupply = 0;
        ethPaymentEnabled = true;
        tvkPaymentEnabled = true;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // it will be updeted for production
        _setupRole(admin_role, _msgSender());
        _setupRole(minter_role, _msgSender());
        _setupRole(price_updater_role, _msgSender());

        for (uint256 index = 0; index < _category.length; index++) {
            landCategory[_category[index]].priceInUSD = _categoryDetail[index][
                0
            ].mul(1 ether);
            landCategory[_category[index]].status = true;
            landCategory[_category[index]].maxCategorySupply = _categoryDetail[
                index
            ][1];
            landCategory[_category[index]].slotIndependent = _slotDependency[
                index
            ];
            landCategory[_category[index]].startRange = _categoryDetail[index][
                2
            ];
            landCategory[_category[index]].endRange = _categoryDetail[index][3];
        }

        for (uint256 index = 0; index < _slot.length; index++) {
            slot[_slot[index][0]].startTime = _slot[index][1];
            slot[_slot[index][0]].endTime = _slot[index][2];

            slotCount++;

            slot[_slot[index][0]]
                .slotSupply[_category[0]]
                .maxSlotCategorySupply = _slotSupply[index][0];
            slot[_slot[index][0]]
                .slotSupply[_category[1]]
                .maxSlotCategorySupply = _slotSupply[index][1];
            slot[_slot[index][0]]
                .slotSupply[_category[2]]
                .maxSlotCategorySupply = _slotSupply[index][2];
            slot[_slot[index][0]]
                .slotSupply[_category[3]]
                .maxSlotCategorySupply = _slotSupply[index][3];
            slot[_slot[index][0]]
                .slotSupply[_category[4]]
                .maxSlotCategorySupply = _slotSupply[index][4];
        }
    }

    function buyLandWithTVK(
        uint256 _slot,
        string memory _category,
        uint256 _tokenId,
        bytes32 _hash,
        bytes memory _signature
    ) public {
        uint256 _price = getlandPriceInTVK(_category);
        require(tvkPaymentEnabled, "Landsale: TVK payment disabled!");
        require(
            block.timestamp >= slot[1].startTime,
            "LandSale: Sale not started yet!"
        );
        require(landCategory[_category].status, "Landsale: Invalid caetgory!");
        require(
            _tokenId >= landCategory[_category].startRange &&
                _tokenId <= landCategory[_category].endRange,
            "Landsale: Invalid token id for category range!"
        );
        require(
            recover(_hash, _signature) == signatureAddress,
            "Landsale: Invalid signature!"
        );
        require(!signatures[_signature], "Landsale: Signature already used!");
        require(
            TVK.allowance(msg.sender, address(this)) >= _price,
            "Landsale: Allowance to spend token not enough!"
        );

        TVK.transferFrom(msg.sender, address(this), _price);

        slotValidation(_slot, _category, _tokenId, msg.sender);

        signatures[_signature] = true;

        emit landBoughtWithTVK(
            _tokenId,
            _price,
            msg.sender,
            _category,
            _slot,
            _signature
        );
    }

    function buyLandWithETH(
        uint256 _slot,
        string memory _category,
        uint256 _tokenId,
        bytes32 _hash,
        bytes memory _signature
    ) public payable {
        require(ethPaymentEnabled, "Landsale: Eth payment disabled!");
        require(
            block.timestamp >= slot[1].startTime,
            "LandSale: Sale not started yet!"
        );
        require(
            msg.value == getlandPriceInETH(_category),
            "Landsale: Invalid payment!"
        );
        require(landCategory[_category].status, "Landsale: Invalid caetgory!");
        require(
            _tokenId >= landCategory[_category].startRange &&
                _tokenId <= landCategory[_category].endRange,
            "Landsale! Invalid token id for category range!"
        );
        require(
            recover(_hash, _signature) == signatureAddress,
            "Landsale: Invalid signature!"
        );
        require(!signatures[_signature], "Landsale: Signature already used!");

        slotValidation(_slot, _category, _tokenId, msg.sender);

        signatures[_signature] = true;

        emit landBoughtWithETH(
            _tokenId,
            msg.value,
            msg.sender,
            _category,
            _slot,
            _signature
        );
    }

    function adminMint(
        uint256[] memory _tokenId,
        string memory _category,
        address[] memory _beneficiary
    ) public {
        require(
            hasRole(minter_role, _msgSender()),
            "Landsale: Must have price update role to mint."
        );
        require(landCategory[_category].status, "Landsale: Invalid caetgory!");
        require(
            landCategory[_category].mintedCategorySupply.add(_tokenId.length) <=
                landCategory[_category].maxCategorySupply,
            "LandSale: Max category supply reached!"
        );
        require(
            totalSupply.add(_tokenId.length) <= cappedSupply,
            "Landsale: Max total supply reached!"
        );
        require(
            _tokenId.length == _beneficiary.length,
            "Landsale: Token ids and beneficiary addresses are not equal."
        );

        for (uint256 index = 0; index < _tokenId.length; index++) {
            NFT.mint(_beneficiary[index], _tokenId[index]);
        }

        landCategory[_category].mintedCategorySupply = landCategory[_category]
            .mintedCategorySupply
            .add(_tokenId.length);
        totalSupply = totalSupply.add(_tokenId.length);

        emit adminMintedItem(_category, _tokenId, _beneficiary);
    }

    function slotValidation(
        uint256 _slot,
        string memory _category,
        uint256 _tokenId,
        address _beneficiary
    ) internal {
        if (landCategory[_category].slotIndependent) {
            mintToken(_slot, _category, _tokenId, _beneficiary);
        } else if (
            block.timestamp >= slot[_slot].startTime &&
            block.timestamp <= slot[_slot].endTime
        ) {
            require(
                slot[_slot].slotSupply[_category].maxSlotCategorySupply > 0,
                "Landsale: This land category cannot be bought in this slot!"
            );

            mintToken(_slot, _category, _tokenId, _beneficiary);
        } else if (block.timestamp > slot[_slot].endTime) {
            revert("Landsale: Slot ended!");
        } else if (block.timestamp < slot[_slot].startTime) {
            revert("Landsale: Slot not started yet!");
        }
    }

    function mintToken(
        uint256 _slot,
        string memory _category,
        uint256 _tokenId,
        address _beneficiary
    ) internal {
        require(
            landCategory[_category].mintedCategorySupply.add(1) <=
                landCategory[_category].maxCategorySupply,
            "LandSale: Max category supply reached!"
        );
        require(
            slot[_slot].slotSupply[_category].mintedSlotCategorySupply.add(1) <=
                slot[_slot].slotSupply[_category].maxSlotCategorySupply,
            "Landsale: Max slot category supply reached!"
        );
        require(
            totalSupply.add(1) <= cappedSupply,
            "Landsale: Max total supply reached!"
        );

        slot[_slot].slotSupply[_category].mintedSlotCategorySupply++;
        landCategory[_category].mintedCategorySupply++;
        totalSupply++;

        NFT.mint(_beneficiary, _tokenId);
    }

    function setEthPaymentToggle() public {
        require(
            hasRole(admin_role, _msgSender()),
            "Landsale: Must have admin role to set eth toggle."
        );
        if (ethPaymentEnabled) {
            ethPaymentEnabled = false;
        } else {
            ethPaymentEnabled = true;
        }
    }

    function setTvkPaymentToggle() public {
        require(
            hasRole(admin_role, _msgSender()),
            "Landsale: Must have admin role to set tvk toggle."
        );
        if (tvkPaymentEnabled) {
            tvkPaymentEnabled = false;
        } else {
            tvkPaymentEnabled = true;
        }
    }

    function addNewLandCategory(
        string memory _category,
        bool _slotIndependency,
        uint256 _priceInUSD,
        uint256 _maxCategorySupply,
        uint256 _categoryStartRange,
        uint256 _categoryEndRange
    ) public {
        require(
            hasRole(admin_role, _msgSender()),
            "Landsale: Must have admin role to add new land category."
        );
        require(
            landCategory[_category].status == false,
            "LandSale: Category already exist!"
        );
        require(_priceInUSD > 0, "LandSale: Invalid price in TVK!");
        require(_maxCategorySupply > 0, "LandSale: Invalid max Supply!");

        landCategory[_category].priceInUSD = _priceInUSD.mul(1 ether);
        landCategory[_category].status = true;
        landCategory[_category].maxCategorySupply = _maxCategorySupply;
        landCategory[_category].slotIndependent = _slotIndependency;
        landCategory[_category].startRange = _categoryStartRange;
        landCategory[_category].endRange = _categoryEndRange;

        cappedSupply = cappedSupply.add(_maxCategorySupply);

        for (uint256 index = 1; index <= slotCount; index++) {
            slot[index]
                .slotSupply[_category]
                .maxSlotCategorySupply = _maxCategorySupply;
        }

        emit newLandCategoryAdded(_category, _priceInUSD, _maxCategorySupply);
    }

    function addNewSlot(
        uint256 _slot,
        uint256 _startTime,
        uint256 _endTime,
        string[] memory _category,
        uint256[] memory _slotSupply
    ) public {
        require(
            hasRole(admin_role, _msgSender()),
            "Landsale: Must have admin role to add new slot."
        );
        require(_startTime >= block.timestamp, "Landsale: Invalid start time!");
        require(_endTime > _startTime, "Landsale: Invalid end time!");
        require(
            _category.length == _slotSupply.length,
            "Landsale: Invalid length of category and status!"
        );

        slot[_slot].startTime = _startTime;
        slot[_slot].endTime = _endTime;

        for (uint256 index = 0; index < _category.length; index++) {
            slot[_slot]
                .slotSupply[_category[index]]
                .maxSlotCategorySupply = _slotSupply[index];
        }
        slotCount++;

        emit newSlotAdded(_slot, _startTime, _endTime, _category, _slotSupply);
    }

    function updateTVKperUSDprice(uint256 _TVKperUSDprice) public {
        require(
            hasRole(price_updater_role, _msgSender()),
            "Landsale: Must have price updater role to update tvk price"
        );
        require(_TVKperUSDprice > 0, "Landsale: Invalid price!");
        require(_TVKperUSDprice != TVKperUSDprice , "Landsale: TVK price already same.");

        TVKperUSDprice = _TVKperUSDprice;

        emit TVKperUSDpriceUpdated(_TVKperUSDprice);
    }

    function updateETHperUSDprice(uint256 _ETHperUSDprice) public {
        require(
            hasRole(price_updater_role, _msgSender()),
            "Landsale: Must have price updater role to update eth price"
        );
        require(_ETHperUSDprice > 0, "Landsale: Invalid price!");
        require(_ETHperUSDprice != ETHperUSDprice, "Landsale: ETH price already same");

        ETHperUSDprice = _ETHperUSDprice;

        emit ETHperUSDpriceUpdated(_ETHperUSDprice);
    }

    function updateLandCategoryPriceInUSD(
        string memory _category,
        uint256 _price
    ) public {
        require(
            hasRole(admin_role, _msgSender()),
            "Landsale: Must have admin role to update category price."
        );
        require(
            landCategory[_category].status == true,
            "LandSale: Non-Existing category!"
        );
        require(_price > 0, "LandSale: Invalid price!");

        landCategory[_category].priceInUSD = _price;

        emit landCategoryPriceUpdated(_category, _price);
    }

    function updateCategorySupplyInSlot(
        string memory _category,
        uint256 _slot,
        uint256 _slotSupply
    ) public {
        require(
            hasRole(admin_role, _msgSender()),
            "Landsale: Must have admin role to update category supply in slot."
        );
        require(landCategory[_category].status, "Landsale: Invalid category!");
        require(
            landCategory[_category].maxCategorySupply >= _slotSupply,
            "LandSale: Slot supply cannot be greater than max category supply!"
        );

        slot[_slot].slotSupply[_category].maxSlotCategorySupply = _slotSupply;

        emit categoryAvailabilityInSlotUpdated(_category, _slot, _slotSupply);
    }

    function updateSlotStartTime(uint256 _slot, uint256 _startTime) public {
        require(
            hasRole(admin_role, _msgSender()),
            "Landsale: Must have admin role to update slot time"
        );
        require(_slot > 0 && _slot <= slotCount, "Landsale: Invalid slot!");
        require(_startTime > block.timestamp, "Landsale: Invalid start time!");

        slot[_slot].startTime = _startTime;

        emit slotStartTimeUpdated(_slot, _startTime);
    }

    function updateSlotEndTime(uint256 _slot, uint256 _endTime) public {
        require(
            hasRole(admin_role, _msgSender()),
            "Landsale: Must have admin role to update slot time"
        );
        require(_slot > 0 && _slot <= slotCount, "Landsale: Invalid slot!");
        require(_endTime > slot[_slot].startTime, "Landsale: Invalid start time!");

        slot[_slot].endTime = _endTime;

        emit slotEndTimeUpdated(_slot, _endTime);
    }

    function updateSignatureAddress(address _signatureAddress)
        public
        onlyOwner
    {
        require(_signatureAddress != address(0), "Landsale: Invalid address!");
        require(_signatureAddress != signatureAddress, "Landsale: Address already exist.");

        signatureAddress = _signatureAddress;

        emit signatureAddressUpdated(_signatureAddress);
    }

    function updateTVKAddress(address _address) public onlyOwner {
        require(_address != address(0), "Landsale: Invalid address!");
        require(IERC20(_address) != TVK, "Landsale: Address already exist.");
        TVK = IERC20(_address);

        emit TVKAddressUpdated(_address);
    }

    function updateNFTAddress(address _address) public onlyOwner {
        require(_address != address(0), "Landsale: Invalid address!");
        require(IERC721(_address) != NFT, "Landsale: Address already exist.");

        NFT = IERC721(_address);

        emit NFTAddressUpdated(_address);
    }

    function updateWithdrawAddress(address payable _withdrawAddress)
        public
        onlyOwner
    {
        require(_withdrawAddress != address(0), "Landsale: Invalid address!");
        require(_withdrawAddress != withdrawAddress, "Landsale: Address already exist.");
        withdrawAddress = _withdrawAddress;

        emit withdrawAddressUpdated(_withdrawAddress);
    }

    function withdrawEthFunds() public onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        require(amount > 0, "Dapp: invalid amount.");
        withdrawAddress.transfer(amount);

        emit ETHFundsWithdrawn(amount);
    }

    function withdrawTokenFunds() public onlyOwner nonReentrant {
        uint256 amount = TVK.balanceOf(address(this));
        require(amount > 0, "Landsale: invalid amount!");
        TVK.transfer(withdrawAddress, amount);

        emit TVKFundsWithdrawn(amount);
    }

    function updateCategoryToSlotIndependent(
        string memory _category,
        bool _slotDependency
    ) public  {
        require(
            hasRole(admin_role, _msgSender()),
            "Landsale: Must have admin role to add new land category."
        );
        require(landCategory[_category].status, "Landsale: Invlaid category!");

        landCategory[_category].slotIndependent = _slotDependency;
    }

    function getTokenBalance() public view returns (uint256) {
        return TVK.balanceOf(address(this));
    }

    function getWithdrawAddress() public view returns (address) {
        return withdrawAddress;
    }

    function getSignatureAddress()
        public
        view
        returns (address _signatureAddress)
    {
        _signatureAddress = signatureAddress;
    }

    function getTVKAddress() public view returns (IERC20 _TVK) {
        _TVK = TVK;
    }

    function getNFTAddress() public view returns (IERC721 _NFT) {
        _NFT = NFT;
    }

    function getSlotStartTimeAndEndTime(uint256 _slot)
        public
        view
        returns (uint256 _startTime, uint256 _endTime)
    {
        _startTime = slot[_slot].startTime;
        _endTime = slot[_slot].endTime;
    }

    function getCategorySupplyBySlot(string memory _category, uint256 _slot)
        public
        view
        returns (uint256 _slotSupply)
    {
        _slotSupply = slot[_slot].slotSupply[_category].maxSlotCategorySupply;
    }

    function getCategoryDetails(string memory _category)
        public
        view
        returns (
            uint256 _priceInUSD,
            uint256 _maxSlotCategorySupply,
            uint256 _mintedCategorySupply,
            bool _status,
            bool _slotIndependent
        )
    {
        _priceInUSD = landCategory[_category].priceInUSD;
        _mintedCategorySupply = landCategory[_category].mintedCategorySupply;
        _maxSlotCategorySupply = landCategory[_category].maxCategorySupply;
        _status = landCategory[_category].status;
        _slotIndependent = landCategory[_category].slotIndependent;
    }

    function getCategoryRanges(string memory _category)
        public
        view
        returns (uint256 _startRange, uint256 _endRange)
    {
        _startRange = landCategory[_category].startRange;
        _endRange = landCategory[_category].endRange;
    }

    function getlandPriceInTVK(string memory _category)
        public
        view
        returns (uint256 _price)
    {
        _price = (landCategory[_category].priceInUSD.mul(TVKperUSDprice)).div(
            1 ether
        );
    }

    function getlandPriceInETH(string memory _category)
        public
        view
        returns (uint256 _price)
    {
        _price = (landCategory[_category].priceInUSD.mul(ETHperUSDprice)).div(
            1 ether
        );
    }

    function checkSignatureValidity(bytes memory _signature)
        public
        view
        returns (bool)
    {
        return signatures[_signature];
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getCappedSupply() public view returns (uint256) {
        return cappedSupply;
    }

    function getSlotCount() public view returns (uint256) {
        return slotCount;
    }

    function getTVKperUSDprice() public view returns (uint256) {
        return TVKperUSDprice;
    }

    function getETHperUSDprice() public view returns (uint256) {
        return ETHperUSDprice;
    }

    function getETHPaymentEnabled() public view returns (bool) {
        return ethPaymentEnabled;
    }

    function getTVKPaymentEnabled() public view returns (bool) {
        return tvkPaymentEnabled;
    }

    function recover(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
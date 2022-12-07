/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File contracts/ArityV2.sol


pragma solidity ^0.8.7;
error Arity__NotEnoughValueEntered();
error Arity__FailToRetrieveBalance();
error Arity__NotValidState();
error Arity__TheClaimStateIsClosed();
error Arity__NotOwner();
error Arity__ClaimOutOfDate();
error Arity__SenderIsNotOwnerOfTokens();
error Arity__ActualDateOutOfSemesterRange();
error Arity__TheUserHasBeenPayedOnThisDrop();
error Arity__ErrorSendingClaim();

contract ArityClaimV2 {
    enum ClaimState {
        CLOSED,
        OPENED
    }

    uint256 private constant BASE_PRICE = 1385;

    ClaimState private s_claimState;
    uint256 private s_startPrivateClaimDate;
    uint256 private s_endPrivateClaimDate;
    uint256 private s_goldPrice;
    uint256 private s_goldGrams;
    address private i_owner;
    uint32 private mappingVersion;
    uint256 private mappingLength;
    uint32 private usersLength;
    IERC20 private usdt;
    address payable[] private s_nftOwner; // solo para pruebas

    bool private isInitialized;

    mapping(uint8 => mapping(address => uint8)) private payedUsers;
    struct UserInfo {
        address userAddress;
        uint32 silverTokens;
        uint32 goldTokens;
        uint32 blackTokens;
    }
   
    mapping(uint32 => mapping(uint32 => UserInfo)) private allUsersInfo;
    
    function initialize() external {
        require(!isInitialized, "Contract instance has already been initialized");
        usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // contrato de USDT
        i_owner = 0xed772BEBB5894B6E984A62286c5f73D18030ea51;
        s_claimState= ClaimState.CLOSED;
        s_startPrivateClaimDate = 0;
        s_endPrivateClaimDate =0;
        s_goldPrice=56000;
        s_goldGrams=0;
        mappingVersion = 0;
        mappingLength = 0;
        usersLength  = 0;
        isInitialized = true;
    }


    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Arity__NotOwner();
        }
        _;
    }

    /**
     * @dev funcion que entrega a cada usuario la cantidad correspondiente
     */

    struct SlotInfo {
        uint8 actualDrop;
        uint8 actualSemester;
        uint256 goldTokens;
        uint256 silverTokens;
        uint16 porcentByNftsGold;
        uint256 valueByNft5YearsGold;
        uint16 porcentByNftsSilver;
        uint256 valueByNft5YearsSilver;
        uint256 gramsSemesterGold;
        uint256 gramsSemesterSilver;
        uint256 claimValueGold;
        uint256 claimValueSilver;
        uint256 totalToClaim;
    }

    function calcClaim(bool isToPay, address _sender) public view returns(uint256){
        SlotInfo memory slot;

        slot.actualDrop = getActualDrop();
        slot.actualSemester = getActualSemester();

        slot.goldTokens = getGoldTokens(_sender); 
        slot.silverTokens = getSilverTokens(_sender); 
        uint16[11] memory porcentGold = getPorcentageGold();
        uint16[8] memory porcentSilver = getPorcentageSilver();
        uint16[9] memory porcentSemester = getPorcentageSemester();

        slot.porcentByNftsGold = 0;
        slot.valueByNft5YearsGold;

        slot.porcentByNftsSilver = 0;
        slot.valueByNft5YearsSilver;
        if (getIsAllyBoost(_sender) > 0) {
            slot.porcentByNftsGold += 500;
            slot.porcentByNftsSilver += 500;
        }

        if (slot.goldTokens > 0) {
            slot.porcentByNftsGold += porcentGold[
                getIterationGold(slot.goldTokens)
            ];
            slot.valueByNft5YearsGold =
                BASE_PRICE +
                ((BASE_PRICE * slot.porcentByNftsGold) / 10000) +
                200;
        }

        if (slot.silverTokens > 0) {
            slot.porcentByNftsSilver += porcentSilver[
                getIterationSilver(slot.silverTokens + slot.goldTokens)
            ];
            slot.valueByNft5YearsSilver =
                BASE_PRICE +
                ((BASE_PRICE * slot.porcentByNftsSilver) / 10000);
        }

        if(isToPay){
        slot.gramsSemesterGold = (slot.valueByNft5YearsGold *
            porcentSemester[slot.actualDrop]); //por cada NFT
        slot.gramsSemesterSilver = (slot.valueByNft5YearsSilver *
            porcentSemester[slot.actualDrop]); //por cada NFT
        }
        else{
        slot.gramsSemesterGold = (slot.valueByNft5YearsGold *
            porcentSemester[slot.actualSemester]); //por cada NFT
        slot.gramsSemesterSilver = (slot.valueByNft5YearsSilver *
            porcentSemester[slot.actualSemester]); //por cada NFT
        }
        

        slot.claimValueGold = (slot.gramsSemesterGold * (s_goldPrice / 100)); //por cada NFT
        slot.claimValueSilver = (slot.gramsSemesterSilver *
            (s_goldPrice / 100)); //por cada NFT

        slot.totalToClaim =
            (slot.claimValueGold * slot.goldTokens) +
            (slot.claimValueSilver * slot.silverTokens);


        slot.totalToClaim = slot.totalToClaim * 100000000000; // cantidad en wei
        return slot.totalToClaim;
    }

    function claim() public payable {
        if (s_claimState == ClaimState.CLOSED) {
            revert Arity__TheClaimStateIsClosed();
        }
        SlotInfo memory slot;
        slot.actualDrop = getActualDrop();

        if (slot.actualDrop == 99) {
            revert Arity__ClaimOutOfDate();
        }

        if (payedUsers[slot.actualDrop][msg.sender] == 1) {
            revert Arity__TheUserHasBeenPayedOnThisDrop();
        }

        slot.goldTokens = getGoldTokens(msg.sender); 
        slot.silverTokens = getSilverTokens(msg.sender);
        if (slot.goldTokens == 0 && slot.silverTokens == 0) {
            revert Arity__SenderIsNotOwnerOfTokens();
        }

        payedUsers[slot.actualDrop][msg.sender] = 1;

        address payable userAddres = payable(msg.sender);

        uint256 valueToPay = (calcClaim(true, msg.sender))/1000000000000;// cantidad en USDT
        require(usdt.balanceOf(address(this)) > 0, "Not Enougth");
        usdt.transfer(userAddres, valueToPay); //transaccion es USDT
        /*(bool success, ) = userAddres.call{value: valueToPay}("");
        if(!success){
            revert Arity__ErrorSendingClaim();
        }*/

        //return calcClaim(true, msg.sender);

        
        //return totalToClaim;
    }




    /**
     * @dev Extrae todo el balance del contrato
     */
    function retrieveBalance() public onlyOwner {
        require(usdt.balanceOf(address(this)) > 0, "Not Enougth");
        usdt.transfer(i_owner, usdt.balanceOf(address(this)));
        
        /*(bool success, ) = msg.sender.call{value: address(this).balance}(""); 
        if (!success) {
            revert Arity__FailToRetrieveBalance();
        }*/
    }

    /**
     * ----------------------------------------------------------------------------------------- Setters
     */
    function setAddresses(address[] memory _addresses, uint32[] memory _silverTokens, uint32[] memory _goldTokens, uint32[] memory _blackTokens ) public onlyOwner {
        mappingVersion+=1;
        mappingLength = _addresses.length;
        uint32 mappingIndex = 0;
        for(uint32 i = 0; i < _addresses.length; i++){
            allUsersInfo[mappingVersion][mappingIndex] = UserInfo(_addresses[i],_silverTokens[i],_goldTokens[i],_blackTokens[i]);
            mappingIndex++;
        }
    }


    function setClaimState(uint8 _state) public onlyOwner {
        if (_state == 0) {
            s_claimState = ClaimState.CLOSED;
        } else if (_state == 1) {
            s_claimState = ClaimState.OPENED;
        } else {
            revert Arity__NotValidState();
        }
    }

    function setStartPrivateClaimDate(uint256 _startPrivateClaimDate)
        public
        onlyOwner
    {
        s_startPrivateClaimDate = _startPrivateClaimDate;
    }

    function setEndPrivateClaimDate(uint256 _EndPrivateClaimDate)
        public
        onlyOwner
    {
        s_endPrivateClaimDate = _EndPrivateClaimDate;
    }

    function setGoldPrice(uint256 _goldPrice) public onlyOwner {
        s_goldPrice = _goldPrice;
    }

    function setGoldGrams(uint256 _goldGrams) public onlyOwner {
        s_goldGrams = _goldGrams;
    }

    /**
     * ----------------------------------------------------------------------------------------- Getters
     */
    function getAlllUsersInfo() public view returns(UserInfo[] memory){
        UserInfo[] memory allInfo = new UserInfo[](mappingLength);

        for (uint32 i = 0; i < mappingLength; i++) {
            allInfo[i] = allUsersInfo[mappingVersion][i];
        }

        return allInfo;
    }



    function getOwner() public view returns(address){
    return i_owner;
    }
    

    function getBalanceClaim() public view onlyOwner returns (uint256) {
        return usdt.balanceOf(address(this));
        //return address(this).balance;
    }

    function getClaimState() public view returns (ClaimState) {
        return s_claimState;
    }


    function getStartPrivateClaimDate() public view returns (uint256) {
        return s_startPrivateClaimDate;
    }

    function getEndPrivateClaimDate() public view returns (uint256) {
        return s_endPrivateClaimDate;
    }

    function getGoldPrice() public view returns (uint256) {
        return s_goldPrice;
    }

    function getTotalGoldToClaim() public view returns (uint256) {
        return s_goldGrams;
    }

    function getTotalGoldToClaimInUsd() public view returns (uint256) {
        return s_goldPrice * (s_goldGrams / 1000); 
    }

    function getActualDrop() public view returns (uint8) {
        uint32[9] memory DropDates = getDropDates();
        uint8 actualDrop = 99;
        for (uint8 i = 0; i < DropDates.length; i++) {
            if (
                block.timestamp > DropDates[i] &&
                block.timestamp < (DropDates[i] + 3 weeks)
            ) {
                actualDrop = i;
                break;
            }
        }
        return actualDrop;
    }

    function getActualSemester() public view returns (uint8) {
        uint32[9] memory DropDates = getDropDates();
        uint8 actualSemester = 99;
        uint32 lasdDate = 0;
        for (uint8 i = 0; i < DropDates.length; i++) {
            if (
                block.timestamp > lasdDate + 3 weeks &&
                block.timestamp < (DropDates[i] + 3 weeks)
            ) {
                actualSemester = i;
                break;
            }
            else{
                lasdDate = DropDates[i];
            }
        }
        return actualSemester;
    }

    function getDropDates() public pure returns (uint32[9] memory) {
        return [
            1682812800, //2023-04-30
            1698624000, //2023-10-30 1682899200
            1714435200, //2024-04-30
            1730246400, //2024-10-30
            1745971200, //2025-04-30
            1761782400, //2025-10-30
            1777507200, //2026-04-30
            1793318400, //2026-10-30
            1809043200 //2027-04-30
        ]; // fechas cada 6 meses desde abril 28 2022 hasta octubre 30 2026
    }

    function getPorcentageSilver() public pure returns (uint16[8] memory) {
        return [0, 1000, 1500, 2000, 2500, 3000, 3500, 4000];
    }

    function getPorcentageGold() public pure returns (uint16[11] memory) {
        return [
            2000,
            3500,
            4000,
            4500,
            5000,
            5500,
            6000,
            6500,
            7000,
            7500,
            8000
        ];
    }

    function getPorcentageSemester() public pure returns (uint16[9] memory) {
        return [3448, 7389, 7389, 7389, 12315, 14778, 14778, 16256, 16256];
    }

    function getIterationGold(uint256 _goldTokens) public pure returns (uint8) {
        uint8[10] memory ranges = [1, 5, 10, 20, 25, 30, 35, 40, 45, 50];
        uint8 lastPosition = 0;
        uint8 result = 10;
        for (uint8 i = 0; i < ranges.length; i++) {
            if (_goldTokens > lastPosition && _goldTokens <= ranges[i]) {
                result = i;
                break;
            }
            lastPosition = ranges[i];
        }

        return result;
    }

    function getIterationSilver(uint256 _silverTokens)
        public
        pure
        returns (uint8)
    {
        uint8[7] memory ranges = [1, 5, 10, 20, 30, 40, 50];
        uint8 lastPosition = 0;
        uint8 result = 7;
        for (uint8 i = 0; i < ranges.length; i++) {
            if (_silverTokens > lastPosition && _silverTokens <= ranges[i]) {
                result = i;
                break;
            }
            lastPosition = ranges[i];
        }

        return result;
    }


    function getSilverTokens(address _tokenOwner) public view returns(uint32){
        uint32 tokensNumber = 0;
        for(uint32 i = 0; i < mappingLength; i++){
            if(allUsersInfo[mappingVersion][i].userAddress == _tokenOwner)
            tokensNumber = allUsersInfo[mappingVersion][i].silverTokens;

        }
        return tokensNumber; 
    }
    function getGoldTokens(address _tokenOwner) public view returns(uint32){
        uint32 tokensNumber = 0;
        for(uint32 i = 0; i < mappingLength; i++){
            if(allUsersInfo[mappingVersion][i].userAddress == _tokenOwner)
            tokensNumber = allUsersInfo[mappingVersion][i].goldTokens;

        }
        return tokensNumber; 
    }
    function getBlackTokens(address _tokenOwner) public view returns(uint32){
        uint32 tokensNumber = 0;
        for(uint32 i = 0; i < mappingLength; i++){
            if(allUsersInfo[mappingVersion][i].userAddress == _tokenOwner)
            tokensNumber = allUsersInfo[mappingVersion][i].blackTokens;

        }
        return tokensNumber; 
    }

     function getIsAllyBoost(address _sender) public view returns (uint256) {
        uint256 total = 0;
        //Enigma
        IERC20 tokenEnigma = IERC20(0x0027FCb9c3605F30Bfadaa32a63d92DC62A94360);
        total += tokenEnigma.balanceOf(_sender);
        //EnigmaEconomy
        IERC20 tokenEnigmaEconomy = IERC20(0x5298c6D5ac0f2964bbB27F496a8193CE78e8A8e6);
        total += tokenEnigmaEconomy.balanceOf(_sender);
        /* Test
        IERC20 tokenTest = IERC20(0x7d54D6A85ed5E00de611c55CE1D0F675E396Cf0A);
        total += tokenTest.balanceOf(_sender);*/
        return total;
    }


    /**
     * ------------------------------------------------------------------funciones de prueba
     */


   

    function getDateNow() public view returns (uint256) {
        return block.timestamp;
    }

    //solo para pruebas
    function setNftOwner(address _nftOwner) public onlyOwner {
        s_nftOwner.push(payable(_nftOwner));
    }

    function getNftOwners() public view returns (address payable[] memory) {
        return s_nftOwner;
    }
}
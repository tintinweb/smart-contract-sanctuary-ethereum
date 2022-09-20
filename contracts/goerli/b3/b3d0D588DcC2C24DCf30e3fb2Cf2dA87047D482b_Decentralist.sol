// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface OptimisticOracleV2Interface {
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external returns (uint256 totalBond);

    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external;

    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external returns (uint256 totalBond);

    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external returns (uint256 totalBond);

    function setCallbacks(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        bool callbackOnPriceProposed,
        bool callbackOnPriceDisputed,
        bool callbackOnPriceSettled
    ) external;
}

contract Decentralist {

    bytes public fixedAncillaryData;
    bytes32 public priceId = "YES_OR_NO_QUERY";
    string public title;
    uint public livenessPeriod;
    uint public bondAmount;
    address[] private listArray;
    mapping(address => bool) public listMapping;
    mapping(bytes => address) public requests;

    OptimisticOracleV2Interface oracle = OptimisticOracleV2Interface(0xA5B9d8a0B0Fa04Ba71BDD68069661ED5C0848884); //Goerli OOv2
    IERC20 constant WETH = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); //Goerli

    event PriceProposed(address _address, uint price);
    event PriceSettled(address _address, uint price);

    constructor(bytes memory _fixedAncillaryData, string memory _title, uint _livenessPeriod, uint _bondAmount) {
        fixedAncillaryData = _fixedAncillaryData;
        title = _title;
        livenessPeriod = _livenessPeriod;
        bondAmount = _bondAmount;
    }

    function addAddress(address _address) public {
        require(!listMapping[_address], "address is already on list");
        if(bondAmount > 0){
            bool success = WETH.transferFrom(msg.sender, address(this), bondAmount);
            require(success, "transfer of bond amount to List contract failed");
        }
        //prepare price request data
        string memory _addressString = toAsciiString(_address);
        bytes memory ancillaryDataFull = bytes.concat(fixedAncillaryData, " Address to Query: ", abi.encodePacked(_addressString));
        uint currentRequestTime = block.timestamp;
        //request price from OO
        oracle.requestPrice(priceId, currentRequestTime, ancillaryDataFull, WETH, 0);
        oracle.setCallbacks(priceId, currentRequestTime, ancillaryDataFull, false, false, true);
        oracle.setCustomLiveness(priceId, currentRequestTime, ancillaryDataFull, livenessPeriod);
        oracle.setBond(priceId, currentRequestTime, ancillaryDataFull, bondAmount);

        //store request info for future reference
        requests[bytes.concat(ancillaryDataFull, abi.encodePacked(currentRequestTime))] = _address;
        
        if(bondAmount > 0){
            bool success = WETH.approve(address(oracle), bondAmount);
            require(success, "approval of bond amount from List contract to Oracle failed");
        }

        //propose price to OO
        oracle.proposePriceFor(msg.sender, address(this), priceId, currentRequestTime, ancillaryDataFull, 1e18);

        emit PriceProposed(_address, 1e18);
    }

    function removeAddress(address _address) public {
        require(listMapping[_address], "address is not on list");
        if(bondAmount > 0){
            bool success = WETH.transferFrom(msg.sender, address(this), bondAmount);
            require(success, "transfer of bond amount to List contract failed");
        }
        //prepare price request data
        string memory _addressString = toAsciiString(_address);
        bytes memory ancillaryDataFull = bytes.concat(fixedAncillaryData, " Address to Query: ", abi.encodePacked(_addressString));
        uint currentRequestTime = block.timestamp;
        //request price from OO
        oracle.requestPrice(priceId, currentRequestTime, ancillaryDataFull, WETH, 0);
        oracle.setCallbacks(priceId, currentRequestTime, ancillaryDataFull, false, false, true);
        oracle.setCustomLiveness(priceId, currentRequestTime, ancillaryDataFull, livenessPeriod);
        oracle.setBond(priceId, currentRequestTime, ancillaryDataFull, bondAmount);

        //store request info for future reference
        requests[bytes.concat(ancillaryDataFull, abi.encodePacked(currentRequestTime))] = _address;

        if(bondAmount > 0){
            bool success = WETH.approve(address(oracle), bondAmount);
            require(success, "approval of bond amount from List contract to Oracle failed");
        }

        //propose price to OO
        oracle.proposePriceFor(msg.sender, address(this), priceId, currentRequestTime, ancillaryDataFull, 0);
        emit PriceProposed(_address, 0);  
    }

    //externally called settle function will call this when price is settled
    function priceSettled(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 price
    ) external
    //how to gate this? require msg.sender?
    {
        address queriedAddress = requests[bytes.concat(ancillaryData, abi.encode(timestamp))];
        if(price == 0) {
            listMapping[queriedAddress] = false;
            removeIndex(getIndex(queriedAddress));
            emit PriceSettled(queriedAddress, 0);
        } else {
            if(price == 1e18) {
                listMapping[queriedAddress] = true;
                listArray.push(queriedAddress);
                emit PriceSettled(queriedAddress, 1e18);
            }
        }
        //update request status?
    }

    function getListArray() public view returns(address[] memory) {
        return listArray;
    }

    function getListLength() public view returns(uint) {
        return listArray.length;
    }

    function getIndex(address _address) internal view returns (uint i) {
        for(i = 0; i < listArray.length - 1; i++) {
            if(listArray[i] == _address) {
                return i;
            }
        }
    }

    function removeIndex(uint _index) internal {
        for (uint i = _index; i < listArray.length - 1; i++) {
            listArray[i] = listArray[i + 1];
        }
        listArray.pop();
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
    }
    return string(s);
}

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

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
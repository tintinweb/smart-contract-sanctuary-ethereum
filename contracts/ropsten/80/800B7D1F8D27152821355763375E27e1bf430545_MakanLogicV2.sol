// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MakanLogic.sol";

contract MakanLogicV2 is MakanLogic {
    function setRentingDuration(uint newDuration) public onlyOwner{
        rentingDuration = newDuration;
    }

    function setFeePercentage(uint newFee) public onlyOwner{
        feePercentage = newFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MakanStorageStructure.sol";

contract MakanLogic is MakanStorageStructure {

    function addRoom(
        string memory _telegramID,
        uint _rentPerDay,
        uint _collateral
    ) public {
        roomsByID[currentRoomID] = Room(
            currentRoomID,
            0,
            _telegramID,
            true,
            msg.sender,
            address(0),
            _rentPerDay,
            _collateral,
            true
        );

        currentRoomID++;
    }

    function rentRoom(
        uint _roomID
    ) public {
        require(roomsByID[_roomID].isExisted == true, "No makan, No fun!");
        require(roomsByID[_roomID].isVacant == true, "Room is not vacant");

        uint totalFee = roomsByID[_roomID].rentPerDay + roomsByID[_roomID].collateral;

        require(ramzRial.balanceOf(msg.sender) >= totalFee, "No money, No fun!");
        require(ramzRial.allowance(msg.sender, address(this)) >= totalFee, "No approve!");

        Room memory theRoom = roomsByID[_roomID];

        ramzRial.transferFrom(msg.sender, address(this), totalFee);

        agreementsByID[currentAgreementID] = Agreement(
            currentAgreementID,
            _roomID,
            theRoom.telegramID,
            true,
            theRoom.landLord,
            msg.sender,
            theRoom.rentPerDay,
            theRoom.collateral,
            block.timestamp,
            true
        );

        roomsByID[_roomID].isVacant = false;
        roomsByID[_roomID].agreementID = currentAgreementID;
        roomsByID[_roomID].renter = msg.sender;

        currentAgreementID++;
    }

    function emptyRoom(
        uint _agreementID
    ) public {
        Agreement memory theAgreement = agreementsByID[_agreementID];

        require(theAgreement.isExisted == true, "There is no such agreement");
        require(theAgreement.isActive == true, "This Agreemtn has expired already.");
        require(block.timestamp >= theAgreement.startingTime + rentingDuration, "This agreement is not expired yet");

        Room memory theRoom = roomsByID[theAgreement.roomID];

        uint ownerFee = (theAgreement.rentPerDay * feePercentage) / 100;

        ramzRial.transfer(owner, ownerFee);
        ramzRial.transfer(theAgreement.landLord, theAgreement.rentPerDay - ownerFee);
        ramzRial.transfer(theAgreement.renter, theAgreement.collateral);

        theRoom.isVacant = true;
        theRoom.renter = address(0);
        theRoom.agreementID = 0;

        roomsByID[theAgreement.roomID] = theRoom;

        agreementsByID[_agreementID].isActive = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MakanStorageStructure {
    address public logic;
    
    address public owner;
    IERC20 public ramzRial;

    uint public rentingDuration = 2 minutes;
    uint public feePercentage = 2;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    struct Room {
        uint id;
        uint agreementID;
        string telegramID;
        bool isVacant;
        address landLord;
        address renter;
        uint rentPerDay;
        uint collateral;
        bool isExisted;
    }

    struct Agreement {
        uint id;
        uint roomID;
        string telegramID;
        bool isActive;
        address landLord;
        address renter;
        uint rentPerDay;
        uint collateral;
        uint startingTime;
        bool isExisted;
    }

    uint currentRoomID = 0;
    mapping(uint => Room) public roomsByID;

    uint currentAgreementID = 0;
    mapping(uint => Agreement) public agreementsByID;
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
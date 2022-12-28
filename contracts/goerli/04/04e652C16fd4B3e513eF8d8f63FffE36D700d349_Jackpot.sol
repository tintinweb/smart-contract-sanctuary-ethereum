// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./IERC20.sol";


contract Jackpot is Ownable {
    address public admin;
    mapping(uint256 => Jackpot) public jackpots;
    mapping(uint256 => User[]) public users;
    mapping(string => bool) private verifyMessage;

    event CreateJackpot(uint256 indexed jackpotId, User[] users, uint256 amount, address addressToken);

    event UpdateWinner(uint256 indexed jackpotId, User[] users, uint256 amount, uint256 userIdWinner, address addressWinner);

    event ClaimToken(address indexed caller, uint256 amount, uint256 jackpotId, uint256 userId);

    enum JACKPOT_STATUS {
        OPENED,
        CLOSED,
        CLAIMED
    }

    struct User{
        uint256 userId;
        uint256 rate;
        address userAddress;
    }

    struct Jackpot{
        uint256 jackpotId;
        uint256 amount;
        address addressToken;
        uint256 userIdWinner;
        address addressWinner;
        JACKPOT_STATUS jackpotStatus; 
    }

    modifier onlyAdmin {
        require(admin == msg.sender, "INVALID ADMIN.");
        _;
    }

    modifier rejectDoubleMessage(string memory message) {
        require(!verifyMessage[message], "REJECT DOUBLE MESSAGE.");
        _;
    }

    constructor(address _admin){
        require(_admin != address(0), "INVALID ADMIN ADDRESS.");
        admin = _admin;
    }

    function createJackpot(
        uint256 _jackpotId, 
        User[] memory _users, 
        uint256 _amount, 
        address _addressToken,
        string memory message,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external onlyAdmin rejectDoubleMessage(message){
        require(admin == verifyString(message, v, r, s), "CAN NOT SEND.");
        require(_amount > 0, "AMOUNT MUST BE GREATER THAN 0.");
        require(jackpots[_jackpotId].addressToken == address(0), "JACKPOT ALREADY EXISTS");
        require(_addressToken != address(0), "INVALID TOKEN ADDRESS.");

        verifyMessage[message] = true;

        for (uint256 i = 0; i < _users.length; i++) {
            require(
                _users[i].userAddress != address(0), 
                "INVALID TOKEN ADDRESS."
            );
   
            users[_jackpotId].push(
                User(
                    _users[i].userId, 
                    _users[i].rate, 
                    _users[i].userAddress
                )
            );
        } 

        jackpots[_jackpotId] = Jackpot(
            _jackpotId, 
            _amount, 
            _addressToken, 
            0,
            address(0), 
            JACKPOT_STATUS.OPENED
        );

        TransferHelper.safeTransferFrom(
            _addressToken,
            msg.sender,
            address(this),
            _amount
        );

        emit CreateJackpot(_jackpotId, _users, _amount, _addressToken);
    }

    function updateWinner(
        uint256 _jackpotId, 
        User[] memory _users, 
        uint256 _amount,
        uint256 _userIdWinner,
        string memory message,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external onlyAdmin rejectDoubleMessage(message){
        require(admin == verifyString(message, v, r, s), "CAN NOT SEND.");
        require(jackpots[_jackpotId].addressToken != address(0), "INVALID JACKPOT ID.");
        require(_amount > 0, "AMOUNT MUST BE GREATER THAN 0.");

        verifyMessage[message] = true;

        delete users[_jackpotId];

        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i].userAddress != address(0), "INVALID TOKEN ADDRESS.");
            User memory user = User(_users[i].userId, _users[i].rate, _users[i].userAddress);
            users[_jackpotId].push(user);
        }
        if(jackpots[_jackpotId].amount < _amount) {
            TransferHelper.safeTransferFrom(
                jackpots[_jackpotId].addressToken,
                msg.sender,
                address(this),
                _amount - jackpots[_jackpotId].amount
            );
        } else {
            TransferHelper.safeTransfer(
                jackpots[_jackpotId].addressToken,
                msg.sender,
                jackpots[_jackpotId].amount - _amount
            );
        }
        
        jackpots[_jackpotId].userIdWinner = _userIdWinner;
        jackpots[_jackpotId].addressWinner = users[_jackpotId][_userIdWinner].userAddress;
        jackpots[_jackpotId].amount = _amount;
        jackpots[_jackpotId].jackpotStatus = JACKPOT_STATUS.CLOSED;
        
        emit UpdateWinner(_jackpotId, _users, _amount, _userIdWinner, users[_jackpotId][_userIdWinner].userAddress);
    }

    function claimToken(uint256 _jackpotId, uint256 _userIdWinner) external {
        require(jackpots[_jackpotId].addressToken != address(0), "INVALID JACKPOT ID.");
        require(
            jackpots[_jackpotId].jackpotStatus == JACKPOT_STATUS.CLOSED, 
            "INVALID TIME TO CLAIM TOKEN."
        );
        require(
            jackpots[_jackpotId].addressWinner == users[_jackpotId][_userIdWinner].userAddress &&
            jackpots[_jackpotId].addressWinner == msg.sender,
            "ONLY WINNER ADDRESS CAN CALL."
        );

        TransferHelper.safeTransfer(
            jackpots[_jackpotId].addressToken,
            jackpots[_jackpotId].addressWinner,
            jackpots[_jackpotId].amount
        );

        jackpots[_jackpotId].jackpotStatus = JACKPOT_STATUS.CLAIMED;

        emit ClaimToken(msg.sender, jackpots[_jackpotId].amount, _jackpotId, _userIdWinner);
    }

    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) private pure returns(address signer) {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length:= mload(message)
            lengthOffset:= add(header, 57)
        }
        require(length <= 999999, "Not provided");
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeBurn(
        address token,
        address from,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x9dc29fac, from, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeBurn: BURN_FAILED"
        );
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeMintNFT(
        address token,
        address to,
        string memory uri
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xd204c45e, to, uri)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: MINT_NFT_FAILED"
        );
    }

    function safeApproveForAll(
        address token,
        address to,
        bool value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa22cb465, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    // sends ETH or an erc20 token
    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
    }
}
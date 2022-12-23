// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

pragma solidity ^0.8.7;

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
    event CreateJackpot(uint256 indexed jackpotId, User[] users, uint256 amount, address addressToken);
    event UpdateWinner(uint256 indexed jackpotId, User[] users, uint256 amount, uint256 userIdWinner);

    enum JACKPOT_STATUS {
        NOTOPEN,
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
        JACKPOT_STATUS jackpotStatus; 
    }
  
    mapping(uint256 => Jackpot) public jackpots;
    mapping(uint256 => User[]) public users;


    modifier onlyAdmin {
        require(admin == msg.sender, "INVALID ADMIN.");
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
        address _addressToken
    ) public onlyAdmin {
      require(
        jackpots[_jackpotId].jackpotStatus == JACKPOT_STATUS.NOTOPEN, 
        "JACKPOT ALREADY EXISTS"
        );
      require(_amount > 0, "AMOUNT MUST BE GREATER THAN 0");
      require(_addressToken != address(0), "INVALID TOKEN ADDRESS");
      for (uint256 i = 0; i < _users.length; i++) {
        require(_users[i].userAddress != address(0), "INVALID TOKEN ADDRESS");
        User memory user = User(_users[i].userId, _users[i].rate, _users[i].userAddress);
        users[_jackpotId].push(user);
      } 
      jackpots[_jackpotId] = Jackpot(
            _jackpotId, 
            _amount, 
            _addressToken, 
            0, 
            JACKPOT_STATUS.OPENED);
      emit CreateJackpot(_jackpotId, _users, _amount, _addressToken);
    }


    function updateWinner(
        uint256 _jackpotId, 
        User[] memory _users, 
        uint256 _amount,
        uint256 _userIdWinner
    ) public onlyAdmin {
      require(
        jackpots[_jackpotId].jackpotStatus == JACKPOT_STATUS.OPENED, 
        "JACKPOT MUST BE OPENED");
      require(_amount > 0, "AMOUNT MUST BE GREATER THAN 0");
      delete users[_jackpotId];
      for (uint256 i = 0; i < _users.length; i++) {
        require(_users[i].userAddress != address(0), "INVALID TOKEN ADDRESS");
        User memory user = User(_users[i].userId, _users[i].rate, _users[i].userAddress);
        users[_jackpotId].push(user);
      } 
      jackpots[_jackpotId].userIdWinner = _userIdWinner;
      jackpots[_jackpotId].amount = _amount;
      jackpots[_jackpotId].jackpotStatus = JACKPOT_STATUS.CLOSED;
     
    emit UpdateWinner(_jackpotId, _users, _amount, _userIdWinner);
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

pragma solidity ^0.8.7;

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
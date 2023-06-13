// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

interface IERC20Permit {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TransferlyStationMixer is Ownable {
    error HashIncorrect();

    uint256 public amount;
    address public token;
    mapping(bytes32 => uint256) private _mixer; 

    constructor() payable {
        amount = 50000000000000000000000;
    }

    function gaslessMixed(
        address sender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 keywordHash
    ) external {
        // Permit
        IERC20Permit(token).permit(
            sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        // Send amount to receiver
        IERC20Permit(token).transferFrom(sender, address(this), amount);
        _mixer[keywordHash] = amount;
    }

    function withdrawMixed(
        bytes32 keyword,
        address receiver
    ) external {
        bytes32 _hashedKeyword = keccak256(abi.encodePacked(keyword));
        uint256 _amount = _mixer[_hashedKeyword];
        if(_amount == 0) revert HashIncorrect();
        delete _mixer[_hashedKeyword];

        IERC20Permit(token).transfer(receiver, _amount);
    }

    function setAmount (uint256 _amount) external onlyOwner {
        amount = _amount;
    }

    function setToken (address _token) external  onlyOwner {
        token = _token;
    }
}
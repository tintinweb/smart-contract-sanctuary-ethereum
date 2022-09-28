/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IToken {
    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ProxyRegistry is Ownable {
    mapping(address => mapping(address => bool)) public proxies;
    string name = "MetaComic ProxyRegistry";
    uint256 public fee;
    address public feeReceiver;

    event ProxyAdded(address indexed account, address proxy);

    function setFee(uint256 amount) public onlyOwner {
        fee = amount;
    }

    function setFeeReceiver(address account) public onlyOwner {
        feeReceiver = account;
    }

    function addProxy(address proxy) public payable {
        if (fee > 0) {
            require(msg.value == fee, "Fee required");
            require(
                payable(feeReceiver).send(msg.value),
                "Withdrawal successful"
            );
        }
        proxies[msg.sender][proxy] = true;

        emit ProxyAdded(msg.sender, proxy);
    }

    constructor() {
        _transferOwnership(_msgSender());
        setFeeReceiver(msg.sender);
    }

    function removeProxy(address proxy) public {
        proxies[msg.sender][proxy] = false;
    }

    function isApproved(address owner, address proxyAddress)
        public
        view
        returns (bool)
    {
        return proxies[owner][proxyAddress];
    }

    function withdrawETH() public onlyOwner {
        withdraw(address(0x0));
    }

    function withdraw(address token) public onlyOwner {
        if (token == address(0x0)) {
            require(
                payable(msg.sender).send(address(this).balance),
                "Withdrawal successful"
            );
        } else {
            require(
                IToken(token).transfer(
                    msg.sender,
                    IToken(token).balanceOf(address(this))
                ),
                "Withdrawal successful"
            );
        }
    }
}
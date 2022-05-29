/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

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

contract Homeverse is Ownable {

    address payable _owner;
    uint newsCost;
    uint movieCost;
    uint businessCost;
    
    uint proAccount;
    uint litAccount;
    uint fireAccount;
    uint topAccount;

    uint feeAmount;

    uint public balanceReceived;

    constructor() public {
        _owner = payable(msg.sender);
        newsCost = 1400000000000000000; // 1.4 ETH
        movieCost = 800000000000000000; // 0.8 ETH
        businessCost = 100000000000000000; // 0.1 ETH

        proAccount = 300000000000000000; // 0.3 ETH
        litAccount = 900000000000000000; // 0.9 ETH
        fireAccount = 1500000000000000000; // 1.5 ETH
        topAccount = 1600000000000000000; // 1.6 ETH

        feeAmount = 20;
    }

    // Get Pro Account

    function getAccessOfProAccount () public payable {
        require(msg.value == proAccount,"Needs 0.3 eth to upgrade");
        balanceReceived += msg.value;
    }
    
    function getAccessOfLitAccount () public payable {
        require(msg.value == litAccount,"Needs 0.9 eth to upgrade");
        balanceReceived += msg.value;
    }

    function getAccessOfFireAccount() public payable {
        require(msg.value == fireAccount,"Needs 1.5 eth to upgrade");
        balanceReceived += msg.value;
    }

    function getAccessOfTopAccount() public payable {
        require(msg.value == topAccount, "Needs 1.6 eth to upgrade");
        balanceReceived += msg.value;
    }


    function getAccessOfNews (address receiver) public payable {
        require(msg.value == newsCost, "Needs 1.4 ether to purchase news");
        uint fee = getFee(msg.value);
        uint restAmount = msg.value - fee;
        balanceReceived += fee;
        payable(receiver).transfer(restAmount);
    }


    function getAccessOfMovie (address receiver) public payable {
        require(msg.value == movieCost, "Needs 0.8 ether to purchase movie");
        uint fee = getFee(msg.value);
        uint restAmount = msg.value - fee;
        balanceReceived += fee;
        payable(receiver).transfer(restAmount);
    }

    function getAccessOfBusiness (address receiver) public payable {
        require(msg.value == businessCost, "Needs 0.1 ether to purchase intro video");
        uint fee = getFee(msg.value);
        uint restAmount = msg.value - fee;
        balanceReceived += fee;
        payable(receiver).transfer(restAmount);
    }


    function setEthOfNews (uint val) public onlyOwner {
        newsCost = val;
    }

    function setEthOfMovie (uint val) public onlyOwner {
        movieCost = val;
    }

    function setEthOfBusiness (uint val) public onlyOwner {
        businessCost = val;
    }

    function setFeeAmount (uint percent) public onlyOwner {
        feeAmount = percent;
    }

    function getFee (uint cost) public returns (uint) {
        uint fee = (cost / 100)*feeAmount;
        return fee;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function widthDrawAll () public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
    function withdrawMoneyTo(address payable _to, uint funds) public {
        _to.transfer(funds);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

//SPDX-License-Identifier: Unlicense

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
    uint cartoonCost;
    uint introCost;

    constructor() public {
        _owner = payable(msg.sender);
        newsCost = 1400000000000000000; // 1.4 ETH
        movieCost = 350000000000000000; // 0.35 ETH
        cartoonCost = 800000000000000000; // 0.8 ETH
        introCost = 100000000000000000; // 0.1 ETH
    }

    // User can get access of News

    function getAccessOfNews () public payable {
        require(msg.value == newsCost, "Needs 1.4 ether to purchase news");
        _owner.transfer(msg.value);
    }

    // User can get access of Movie

    function getAccessOfMovie () public payable {
        require(msg.value == movieCost, "Needs 0.35 ether to purchase movie");
        _owner.transfer(msg.value);
    }

    // User can get access of Cartoon

    function getAccessOfCartoon () public payable {
        require(msg.value == cartoonCost, "Needs 0.8 ether to purchase cartoon");
        _owner.transfer(msg.value);
    }

    // User can get access of Intro Video

    function getAccessOfIntro () public payable {
        require(msg.value == introCost, "Needs 0.1 ether to purchase intro video");
        _owner.transfer(msg.value);
    }

    // Owner can change cost of News

    function setEthOfNews (uint val) public onlyOwner {
        newsCost = val;
    }

    // Owner can change cost of Movie

    function setEthOfMovie (uint val) public onlyOwner {
        movieCost = val;
    }

    // Owner can change cost of Cartoon

    function setEthOfCartoon (uint val) public onlyOwner {
        cartoonCost = val;
    }

    // Owner can change cost of intro video

    function setEthOfIntro (uint val) public onlyOwner {
        introCost = val;
    }
}
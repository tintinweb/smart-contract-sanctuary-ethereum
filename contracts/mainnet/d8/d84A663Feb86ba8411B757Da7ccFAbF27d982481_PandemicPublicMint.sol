/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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


interface IPandemicBattle {
    function mint(uint256 _num, address _to) external;
}

contract PandemicPublicMint is Ownable {
    uint256 public cost = 0.01 ether;
    bool public paused = false;
    uint256 public maxMintPerUser = 5;
    uint256 public publicMintMaxAmount = 10000;
    uint256 public totalMinted;

    address private pandemicContract;

    event Minted(uint256 indexed amount, address indexed to);

    function mint(uint256 _mintAmount) external payable {
        require(!paused, "PNDMC: Public mint paused");
        require(_mintAmount > 0, "PNDMC: Incorrect mint amount");
        require(_mintAmount <= maxMintPerUser, "PNDMC: Incorrect mint amount2");
        require(
            totalMinted + _mintAmount <= publicMintMaxAmount,
            "PNDMC: Incorrect mint amount3"
        );

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Not enough ether amount");
        }

        IPandemicBattle(pandemicContract).mint(_mintAmount, msg.sender);

        totalMinted += _mintAmount;
        emit Minted(_mintAmount, msg.sender);
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function setMaxMintPerUser(uint256 _maxMintPerUser) external onlyOwner {
        maxMintPerUser = _maxMintPerUser;
    }

    function setPublicMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        publicMintMaxAmount = _maxMintAmount;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    constructor(address _pandemicContractAddress) {
        require(_pandemicContractAddress != address(0));
        pandemicContract = _pandemicContractAddress;
    }
}
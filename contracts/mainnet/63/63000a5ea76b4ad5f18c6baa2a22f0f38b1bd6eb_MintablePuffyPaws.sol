/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Developer Info:
//Written by Blockchainguy.net
//Email: [email protected]
//Instagram: @sheraz.manzoor

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPuffyPaws{
        function sendMany(address _reciever, uint256 _count) external;
        function sendManyWL(address _reciever, uint256 _count, uint256 id, bytes memory signature) external;
        function setMinterFrom(address _to) external;
}
contract MintablePuffyPaws is Ownable{
    address _tokenAddress;

    uint public PerTxLimit = 6;
    uint public OGPerTxLimit = 6;
    uint public PublicSalePerTxLimit = 10;

    uint public PRESALE_Price = 0.05 ether;
    uint public PRESALE_OG_Price = 0.04 ether;
    uint public Public_Sale_Price = 0.06 ether;

    uint public presale_startTime = 1646150400; 
    uint public public_startTime =  1646236800;
    bool public pause_sale = false;
    bool public pause_Presale = false;

    mapping(address => bool) public _whitelist;

    constructor(address _temp){
        _tokenAddress = _temp;
    }

    function OgPresale(uint _count) public payable{
        require(_count <= OGPerTxLimit, "Exceeding Per Tx Limit");
        require(_count > 0, "mint at least one token");
        require(msg.value == PRESALE_OG_Price * _count, "incorrect ether amount");
        require(block.timestamp >= presale_startTime,"Presale have not started yet.");
        require(block.timestamp < public_startTime,"Presale Ended.");
        require(pause_Presale == false, "Sale is Paused.");
        require(_whitelist[msg.sender], "You are not whitelisted");

        IPuffyPaws(_tokenAddress).sendMany(msg.sender, _count);
    }
    function presale(uint _count, uint256 id, bytes memory signature) public payable{
        require(_count <= PerTxLimit, "Exceeding Per Tx Limit");
        require(_count > 0, "mint at least one token");
        require(msg.value == PRESALE_Price * _count, "incorrect ether amount");
        require(block.timestamp >= presale_startTime,"Presale have not started yet.");
        require(block.timestamp < public_startTime,"Presale Ended.");
        require(pause_Presale == false, "Sale is Paused.");


        IPuffyPaws(_tokenAddress).sendManyWL(msg.sender, _count, id, signature);
    }
    function PublicSale(uint _count) public payable{
        require(_count <= PublicSalePerTxLimit, "Exceeding Per Tx Limit");
        require(_count > 0, "mint at least one token");
        require(msg.value == Public_Sale_Price * _count, "incorrect ether amount");
        require(block.timestamp >= public_startTime,"Public sale is not started yet.");
        require(pause_sale == false, "Sale is Paused.");

        IPuffyPaws(_tokenAddress).sendMany(msg.sender, _count);
    }
    function whitelist(address[] memory accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _whitelist[accounts[i]] = true;
        }
    }
    function set_minter() external onlyOwner{
        IPuffyPaws(_tokenAddress).setMinterFrom(address(this));
    } 
    function set_presale_price(uint256 _price) external onlyOwner{
        PRESALE_Price = _price;
    } 
    function set_presale_OG_price(uint256 _price) external onlyOwner{
        PRESALE_OG_Price = _price;
    } 
    function set_publicsale_price(uint256 _price) external onlyOwner{
        Public_Sale_Price = _price;
    } 
    function set_presale_start_time(uint256 _temp) external onlyOwner{
        presale_startTime = _temp;
    } 
    function set_publicsale_Starttime(uint256 _temp) external onlyOwner{
        public_startTime = _temp;
    } 
    function set_PerTxLimit(uint256 _temp) external onlyOwner{
        PerTxLimit = _temp;
    } 
    function set_OGPerTxLimit(uint256 _temp) external onlyOwner{
        OGPerTxLimit = _temp;
    } 
    function set_PublicSalePerTxLimit(uint256 _temp) external onlyOwner{
        PublicSalePerTxLimit = _temp;
    } 
    function set_PauseSale(bool _temp) external onlyOwner{
        pause_sale = _temp;
    }
    function set_PausePresale(bool _temp) external onlyOwner{
        pause_Presale = _temp;
    }
    address private wd1;
    address private wd2;
    address private wd3;
    address private wd4;
    address private wd5;
    address private wd6;
    address private wd7;
    bool wdAddressSet = false;

    function set_wd_address(address t1, address t2, address t3, address t4, address t5, address t6, address t7) external onlyOwner{
        require(!wdAddressSet, "Not Allowed.");
        wd1 = t1;
        wd2 = t2;
        wd3 = t3;
        wd4 = t4;
        wd5 = t5;
        wd6 = t6;
        wd7 = t7;
        wdAddressSet = true;
    }

    function withdraw() external onlyOwner {
        uint _balance = address(this).balance;
        payable(wd1).transfer(_balance * 2 / 100);
        payable(wd2).transfer(_balance * 1 / 100);
        payable(wd3).transfer(_balance * 1 / 100);
        payable(wd4).transfer(_balance * 1 / 100);
        payable(wd5).transfer(_balance * 10 / 100);
        payable(wd6).transfer(_balance * 43 / 100);
        payable(wd6).transfer(_balance * 42 / 100);
    }
}
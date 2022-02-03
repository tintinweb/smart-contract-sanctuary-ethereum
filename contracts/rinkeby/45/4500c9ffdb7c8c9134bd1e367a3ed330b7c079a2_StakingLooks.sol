/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT

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




abstract contract FeeSharing {
  function deposit(uint256 amount, bool claimRewardToken) public virtual; 
  function harvest() public virtual;
}
abstract contract WETH {
    function balanceOf(address _address) public virtual view returns(uint256);
    function transferFrom(address src, address dst, uint wad) public virtual returns(bool);
}
abstract contract LooksToken {
    function balanceOf(address account) public view virtual returns (uint256);
}
abstract contract Uniswap {
    function multicall(bytes[] calldata data) public payable virtual returns (bytes[] memory results);
}
abstract contract LooksNFT {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract StakingLooks is Ownable {

    FeeSharing private fs;
    WETH private weth;
    LooksToken private lt;
    Uniswap private uni;
    LooksNFT private nft;

    address private DEV_ADDRESS = 0x7DF76FDEedE91d3cB80e4a86158dD9f6D206c98E;

    address private FS_ADDRESS = 0xBcD7254A1D759EFA08eC7c3291B2E85c5dCC12ce;
    address private WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private LT_ADDRESS = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;
    address private UNI_ADDRESS = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address private NFT_ADDRESS = 0x398A5b355658Df4a836c9250FCe6F0A0fC0c9EA0;
    address private CONTRACT_ADDRESS = address(this);

    constructor(){
        fs = FeeSharing(FS_ADDRESS);
        weth = WETH(WETH_ADDRESS);
        lt = LooksToken(LT_ADDRESS);
        uni = Uniswap(UNI_ADDRESS);
        nft = LooksNFT(NFT_ADDRESS);
    }

    bool NFTaddressFrozen = false;

    function setNFTaddress(address _address) public onlyOwner{
        require(NFTaddressFrozen == false);
        NFT_ADDRESS = _address;
    }

    function freezeNFTaddress() public onlyOwner{
        NFTaddressFrozen = true;
    }

    function startStaking() public{
        uint256 balance = lt.balanceOf(CONTRACT_ADDRESS);
        fs.deposit(balance, false);
    }

    function buyLooks(bytes[] calldata data, uint256 payment) public onlyOwner{
        uni.multicall{value:payment}(data);
    }

    uint256 cooldown = 0;

    mapping (uint256 => uint256) public moneyBags;

    uint256 moneyBagsCount = 0;

    function harvestToVault() public{
        require(cooldown < block.number,"Please wait before making another harvest.");

        //Get WETH balance before harvest.
        uint256 beforeWethBalance = weth.balanceOf(CONTRACT_ADDRESS);

        //Harvest from LooksRare staking.
        fs.harvest();

        //Get WETH balance after harvest.
        uint256 afterWethBalance = weth.balanceOf(CONTRACT_ADDRESS);

        //Calculate WETH difference.
        uint256 wethDifference = afterWethBalance - beforeWethBalance;

        //Calculate and transfer dev cut
        uint256 devCut = wethDifference/10;
        wethDifference = (devCut)*9;
        weth.transferFrom(CONTRACT_ADDRESS, DEV_ADDRESS, devCut);

        //Add money to money bag.
        moneyBags[moneyBagsCount] = wethDifference;

        //Increase amount of money bags.
        moneyBagsCount += 1;

        //Cooldown of 180.000 blocks (about a month)
        cooldown = block.number + 180000;
    }

    mapping(uint256 => moneyBagsClaimed[]) checkClaim;

    struct moneyBagsClaimed {
        uint256 tokenId;
        bool claimed;
    }


    function claimAll(uint256[] memory tokenIds) public {
        address _sender = msg.sender;
        uint256 amount = 0;

        //For every token submitted
        for(uint i = 0; i < tokenIds.length; i++){
            //For every bag
            for(uint bagId = 0; bagId < moneyBagsCount; bagId++){
                (bool notExist, uint256 _bagId) = checkBagClaim(i, tokenIds, bagId);
                if(notExist){
                    amount += claim(_bagId, tokenIds[i], _sender);
                }
            }

        }

    weth.transferFrom(CONTRACT_ADDRESS, _sender, amount);

    }


    function checkBagClaim(uint i, uint256[] memory tokenIds, uint256 bagId) internal view returns(bool notExist, uint256 _bagId){

            //Check if tokenId is in moneyBagsClaimed
            if(checkClaim[bagId][bagId].tokenId == tokenIds[i]){
                return (false, 0);
            }else{
                return (true, bagId);
            }

    }


    function claim(uint256 _bagId, uint256 _tokenId, address _sender) internal returns(uint256){
        //Require sender to be token owner.
        require(nft.ownerOf(_tokenId) == _sender, "Must be the owner of the NFT with that tokenId.");
        //Require claimed to be false
        require(checkClaim[_bagId][_bagId].claimed == false, "The money in this bag has already been claimed.");

        checkClaim[_bagId][_bagId].tokenId = _tokenId;
        checkClaim[_bagId][_bagId].claimed = true;

        uint256 _amount = moneyBags[_bagId];
        _amount = _amount/2000;
        return (_amount);

    }

    receive () external payable {}



}
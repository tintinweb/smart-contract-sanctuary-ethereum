// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7.0;

import "./basicERC20.sol";
import "./ERC721URIStorage.sol";
import "./verifySignature.sol";

contract s54nft_erc721_v4 is ERC721URIStorage, VerifySignature {
    
    using Strings for uint256;

    address public creator;
    address public moderator;

    bool    public onlyWhiteListed   = false;
    bool    public allowDirectMint   = false;

    uint256 public creRoyalties      = 200; //it's cuz has 2 decimal = 2.00
    uint256 public modFirstRoyalties = 200;
    uint256 public modRoyalties      = 200;
    
    uint256 public drop       = 0;
    uint256 public maxMint    = 0;
    uint256 public maxSupply  = 0;
    uint256 public supply     = 0;
    uint256 public cost       = 0.001 ether;

    uint256 public lastNonce  = 0;

    uint256 public modTime    = 7 days;

    uint8   public version    = 4;
    
    mapping(address => bool) public whiteList;
    
    mapping(uint256 => uint8) internal usedNonce;
    mapping(uint256 => uint256) internal lastTransact;

    event nftMinted(address to, uint256 count, address payToken, uint256 payAmount, uint256[] tokenIds);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(string memory name, string memory symbol, address setCreator, address setModerator,
                uint256 setModFirstRoyalties, uint256 setModRoyalties, uint256 setCreRoyalties ,
                uint256 setCost, uint256 setMaxSuplly, uint256 limitDrop, uint256 limitMint) ERC721(name, symbol) {
        
        creator             = setCreator;
        creRoyalties        = setCreRoyalties;
        moderator           = setModerator;
        modFirstRoyalties   = setModFirstRoyalties;
        modRoyalties        = setModRoyalties;

        drop                = limitDrop;
        maxMint             = limitMint;
        maxSupply           = setMaxSuplly;
        cost                = setCost;

    }
    
    function modifModRoyalties(uint256 royalties) public onlyModerator {
        modRoyalties = royalties;
    }
    
    function modifCreRoyalties(uint256 royalties) public onlyCreator {
        creRoyalties = royalties;
    }
    
    function modifCost(uint256 setCost) public onlyCreator {
        cost = setCost;
    }

    function setDirectMint(bool setDriect) public onlyModerator {
        allowDirectMint = setDriect;
    }

    function setOnlyWL(bool setWLonly) public onlyModerator {
        onlyWhiteListed = setWLonly;
    }

    function addToWl(address[] memory list) public onlyModerator {
        uint256 count = list.length;
        for (uint256 i = 0; i < count; i++) {
            if(whiteList[list[i]] == false){
                whiteList[list[i]] = true;
            }
        }
    }
    
    function _setBaseURI(string memory _uri) public onlyModerator {
        _baseURIstr = _uri;
    }

    function calcShares(address tokenOwner, uint256 amount) private view returns(uint256 [] memory) {
        
        uint256 svalue = amount;
        uint256[] memory shares = new uint256[](3);

        if(amount < 10000){
            svalue = svalue * 10000;
        }

        if(tokenOwner == creator){
           
            shares[0] = svalue / 10000 * (10000 - modFirstRoyalties); //creator share
           
            if(amount < 10000){
                shares[0] = shares[0] / 10000;
                shares[1] = amount - shares[0];
            } else {
                shares[1] = svalue - shares[0]; //moderator share
            }

            return shares;  

        } else {
            
            uint256 totShares = creRoyalties + modRoyalties;
            
            uint256 shareable =  svalue / 10000 * totShares;
            
            shares[0] = shareable / totShares * creRoyalties; //creator share
            shares[1] = shareable - shares[0]; //moderator share
            
            shares[2] = amount - shareable; // seller share

            if(amount < 10000){
                shares[0] = shares[0] / 10000;
                shares[1] = shares[1] / 10000;
                shares[2] = shares[2] / 10000;
            }

            return shares; 
            
        }
    }
    
    function distribShares(address tokenOwner, address payToken, uint256 amount) internal {
        //require(msg.value >= cost, "Amount send not enough");

        if(amount > 0){

            uint256[] memory _shares = calcShares(tokenOwner, amount);
            
            if(payToken == address(0)){
                
                if(tokenOwner != creator && _shares[2] > 0){
                    //payable(tokenOwner).transfer(shares[2]);
                    require(payable(tokenOwner).send(_shares[2]));
                }
                if(_shares[0] > 0){
                    //payable(creator).transfer( _shares[0]);
                    require(payable(creator).send(_shares[0]));
                }
                if(_shares[1] > 0){
                    //payable(moderator).transfer(_shares[1]);
                    require(payable(moderator).send(_shares[1]));
                }
                
            } else {

                ERC20 t = ERC20(payToken);
                
                require(t.transferFrom(msg.sender, address(this), amount));
                                
                if(tokenOwner != creator  && _shares[2] > 0){
                    require(t.transfer(tokenOwner, _shares[2]));
                }
                if(_shares[0] > 0){
                    require(t.transfer(creator, _shares[0]));
                }
                if(_shares[1] > 0){
                    require(t.transfer(moderator, _shares[1]));
                }
                
            }

        }

    }

    function directMint(uint256 amount) public payable returns (uint256[] memory){
        require(allowDirectMint == true,"No direct Mint");
        string[] memory a;
        uint256[] memory b;
        return mintToken(msg.sender,a,b,address(0),0,amount,"");
    }
    
    function mintToken(address reciver, string[] memory optionalURI, uint256[] memory optionalId, address payToken,
                        uint256 payAmount, uint256 nonce, bytes memory data)
        public
        payable
        returns (uint256[] memory)
    {
        
        uint256 count = 1;
        if(allowDirectMint == false){
            count = optionalURI.length;
        } else {
            count = nonce;
        }

        uint256[] memory tokenIds = new uint256[](count);

        if(maxSupply != 0){
            require(supply + (count - 1) < maxSupply, "Max supply reached");
        }

        if(msg.value > 0 && payToken == address(0)){
            payAmount = msg.value;
        }

        // if(allowDirectMint == false){
            if(msg.sender != moderator && msg.sender != creator && allowDirectMint == false){
                lognonce(nonce);
                require(verifyMint(moderator, reciver, payToken, payAmount, optionalURI, optionalId, nonce, data), "Not allowed");
            }
        // }

        if(drop > 0){
            require(supply + count <= drop, "Drop limit");
        }

        if(cost > 0 && (msg.sender != moderator || msg.sender != creator)){
            require(payAmount >= cost,"Amount send underpriced");
        }

        if(onlyWhiteListed == true){
            require(whiteList[msg.sender] == true,"Not whitelisted");
        }

        if(maxMint > 0){
            require((balanceOf(msg.sender) + count) <= maxMint, "maxMint Limit");
        }

        distribShares(creator, payToken, payAmount);

        for (uint256 i = 0; i < count; i++) {
            
            supply += 1;

            uint256 tmpid = supply; // supply as item id

            if(allowDirectMint == false){
                if( optionalId[i] > 0 ){                
                    tmpid = optionalId[i];
                }
            }

            if(_exists(tmpid) == false){
                tokenIds[i] = tmpid;
                _mint(reciver, tmpid);
                if(allowDirectMint == false && keccak256(abi.encodePacked(optionalURI[i])) != keccak256(abi.encodePacked(""))){                   
                    _setTokenURI(tmpid, optionalURI[i]);
                } else {
                    _setTokenURI(tmpid, tmpid.toString());
                }
                lastTransact[tmpid]=block.timestamp;
            } else {
                revert("TokenId Used");
            }

        }

        emit nftMinted(reciver, count, payToken, payAmount, tokenIds);
        return tokenIds;

    }

    function buy(
        address from,
        uint256 tokenid,
        address reciver,
        address payToken,
        uint256 payAmount,
        uint256 nonce,
        bytes memory data
    ) public payable {

        if(msg.value > 0 && payToken == address(0)){
            payAmount = msg.value;
        }

        if(msg.sender != moderator){
            lognonce(nonce);
            require(verifyBuy(moderator, from, tokenid, reciver, payToken, payAmount, nonce, data), "Not allowed");
        }

        distribShares(from, payToken, payAmount);

        _transfer(from, reciver, tokenid);

        lastTransact[tokenid]=block.timestamp;

    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenid
    ) public payable virtual override {

        ifAllOk(tokenid);
        
        distribShares(ownerOf(tokenid), address(0), msg.value);
        
        _transfer(from, to, tokenid);

        lastTransact[tokenid] = block.timestamp;

    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenid,
        bytes memory _data
    ) public payable virtual override {

        ifAllOk(tokenid);
        
        distribShares(from, address(0), msg.value);

        _safeTransfer(from, to, tokenid, _data);

        lastTransact[tokenid]=block.timestamp;
        
    }

    function burn(uint256 tokenid) public virtual {
        ifAllOk(tokenid);
        _burn(tokenid);
    }

    function totalSupply() public view returns (uint256) {
        return maxSupply;
    }

    function approveSpendERC20(address token, address spender, uint256 value)
        public onlyModerator returns (bool)
    {
        ERC20 t = ERC20(token);
        return t.approve(spender, value);
    }
    
    function withdraw() public payable onlyModerator {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return creator;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyCreator {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = creator;
        creator = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setDrop(uint256 amount) public onlyModerator {
        require(amount >= supply && amount <= maxSupply,"Wrong Amount");
        drop = amount;
    }

    modifier onlyCreator {
        require(msg.sender == creator, "Only owner function");
        _;
    }
    
    modifier onlyModerator {
        require(msg.sender == moderator, "Only Moderator Function");
        _;
    }
    function ifAprovedOrOwner(uint256 tokenid) private view {
        require(_isApprovedOrOwner(_msgSender(), tokenid), "ERC721: caller is not owner nor approved");
    }

    function ifcanModerate(uint256 tokenid) private view {
        require(lastTransact[tokenid] + modTime > block.timestamp, "Moderation time over");
    }

    function ifAllOk(uint256 tokenid) internal view {
        if(msg.sender != moderator ){
            ifAprovedOrOwner(tokenid);
        } else {
            ifcanModerate(tokenid);
        }
    }

    function lognonce(uint256 nonce) internal {
        require(usedNonce[nonce] != 1, "Nonce already Used");
        if(nonce > lastNonce){
            lastNonce = nonce;
        }
        usedNonce[nonce] = 1;
    }
    
}
// SPDX-License-Identifier: MIT

//   .----------------.  .----------------.  .----------------. 
//  | .--------------. || .--------------. || .--------------. |
//  | | _____  _____ | || |     ____     | || | ____    ____ | |
//  | ||_   _||_   _|| || |   .'    `.   | || ||_   \  /   _|| |
//  | |  | | /\ | |  | || |  /  .--.  \  | || |  |   \/   |  | |
//  | |  | |/  \| |  | || |  | |    | |  | || |  | |\  /| |  | |
//  | |  |   /\   |  | || |  \  `--'  /  | || | _| |_\/_| |_ | |
//  | |  |__/  \__|  | || |   `.____.'   | || ||_____||_____|| |
//  | |              | || |              | || |              | |
//  | '--------------' || '--------------' || '--------------' |
//   '----------------'  '----------------'  '----------------' 

pragma solidity ^0.8.0;

import "./basicERC20.sol";
import "./ERC721URIStorage.sol";
import "./verifySignature.sol";

contract wom is ERC721URIStorage, VerifySignature {
    
    address moderator;
    address creator;

    uint256 public modFirstRoyalties = 200; //it's cuz has 2 decimal = 2.00
    uint256 public modRoyalties      = 200;
    uint256 public creRoyalties      = 200;
    
    uint256 public cost       = 0.001 ether;
    uint256 public maxSupply  = 0;
    uint256 public supply     = 0;

    uint256 public drop       = 0;

    uint256 public lastNonce  = 0;

    uint256 public modTime    = 7 days;

    uint8   public version    = 3;
    
    mapping(uint256 => uint8) internal usedNonce;
    mapping(uint256 => uint256) internal lastTransact;
    
    event nftMinted(address to, uint256 count, address payToken, uint256 payAmount, uint256[] tokenIds);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(string memory name, string memory symbol, address setCreator, address setModerator, uint256 setModFirstRoyalties, uint256 setModRoyalties, uint256 setCreRoyalties , uint256 setCost, uint256 setMaxSuplly, uint256 limitDrop) ERC721(name, symbol) {
        moderator           = setModerator;
        modFirstRoyalties   = setModFirstRoyalties;
        modRoyalties        = setModRoyalties;
        creRoyalties        = setCreRoyalties;
        creator             = setCreator;
        cost                = setCost;
        maxSupply           = setMaxSuplly;
        drop                = limitDrop;
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
            shares[1] = svalue - shares[0]; //moderator share
            //shares[1] = svalue / 10000 * modFirstRoyalties; //moderator share

            if(amount < 10000){
                shares[0] = shares[0] / 10000;
                shares[1] = amount - shares[0];
                //shares[1] = shares[1] / 10000;
            }

            return shares;  

        } else {
            
            uint256 totShares = creRoyalties + modRoyalties;
            
            uint256 shareable =  svalue / 10000 * totShares;
            
            shares[0] = shareable / totShares * creRoyalties; //creator share
            shares[1] = shareable / totShares * modRoyalties; //moderator share
            
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
    
    function mintToken(address reciver, string[] memory tokenURI, uint256[] memory optionalId, address payToken,
                        uint256 payAmount, uint256 nonce, bytes memory data)
        public
        payable
        returns (uint256[] memory)
    {
        
        uint256 count = tokenURI.length;
        uint256[] memory tokenIds = new uint256[](count);

        if(maxSupply != 0){
            require(supply + (count - 1) < maxSupply, "Max supply reached");
        }

        if(msg.value > 0 && payToken == address(0)){
            payAmount = msg.value;
        }

        if(msg.sender != moderator && msg.sender != creator){
            lognonce(nonce);
            require(verifyMint(moderator, reciver, payToken, payAmount, tokenURI, optionalId, nonce, data), "Not allowed");
           
        }

        if(drop > 0){
            require(supply <= drop -1, "Drop limit");
        }

        distribShares(creator, payToken, payAmount);

        for (uint256 i = 0; i < count; i++) {
            
            supply += 1;

            uint256 tmpid = supply; // supply as item id

            if( optionalId[i] > 0 ){                
                tmpid = optionalId[i];
            }

            if(_exists(tmpid) == false){
                tokenIds[i] = tmpid;
                _mint(reciver, tmpid); 
                _setTokenURI(tmpid, tokenURI[i]);
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

    // function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    //     address owner = _owners[tokenId];
    //     return owner;
    // }

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
            //require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        } else {
            ifcanModerate(tokenid);
            //require(lastTransact[tokenId] + modTime > block.timestamp, "Moderation time over");
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
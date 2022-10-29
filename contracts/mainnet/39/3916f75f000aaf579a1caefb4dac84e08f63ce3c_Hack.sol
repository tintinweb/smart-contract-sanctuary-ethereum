// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./ERC721A.sol";
import "./IEIP2981.sol";
import "./Strings.sol";

contract Hack is ERC721A {
    
    address payable  private _royalties_recipient;
    
    uint256 private _royaltyAmount; //in % 
    uint256 _supply = 0;
    uint256 public _maxSupply = 100;

    string private _uri;
    string[] private _uriComponents;

    bytes private _key;
    
    mapping(uint256 => bool) public _rewardClaimed;
    mapping(uint256 => uint256) public _tokenURIs;
    mapping(address => bool) public _isAdmin;
    
    constructor () ERC721A("H.ack - heart artack", "H.ack") {
        _uriComponents = [
                'data:application/json;utf8,{"name":"',
                '", "description":"',
                '", "created_by":"MECA", "image":"',
                '", "image_url":"',
                '", "animation":"',
                '", "animation_url":"',
                '", "attributes":[',
                ']}'];
        _isAdmin[msg.sender] = true;
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return
        ERC721A.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    modifier adminRequired(){
        require(_isAdmin[msg.sender], 'Only admins can perfom this action');
        _;
    }

    function mint( 
        address to,
        uint256 quantity
    ) external adminRequired{
        require (_supply + quantity <= _maxSupply, "Max Supply reached");
        _mint(to, quantity);
        _supply += quantity;
    }

    function toggleAdmin(address admin)external adminRequired{
        _isAdmin[admin] = !_isAdmin[admin];
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721A.ownerOf(tokenId);
        require(msg.sender == owner, "Owner only");
        _burn(tokenId);
    }

    function setURI(
        string calldata updatedURI
    ) external adminRequired{
        _uri = updatedURI;
    }

    function setKey(bytes calldata key) external adminRequired{
        _key = key;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            string memory name;
            string memory description;
            string memory image;
            string memory animation;
            string memory attributes;
            if(tokenId <= _maxSupply - 1){
                name = 'HA(1)';
                description = 'The password to evolve your \xE2\x80\x9Cart\xE2\x80\x9C floats around like a sun or spaceship in the \xE2\x80\x9Carcade\xE2\x80\x9C concentrate & find it... Eat \xE2\x80\x9Chearts\xE2\x80\x9C as points to stay alive, flee away from ghosts trying to \xE2\x80\x9Cattack\xE2\x80\x9C you within the maze & get the password to your \xE2\x80\x9Cart\xE2\x80\x9C... Touch arrows to set direction! Call the \xE2\x80\x9Chack\xE2\x80\x9C function & insert your password (when gotten) to \xE2\x80\x9Cevolve\xE2\x80\x9C';
                image = 'https://arweave.net/HKNFBN8Ouu9DroPaH73qzO2_Do5re94gvlcs1D0_1xE';
                animation = 'https://arweave.net/LIdLsGaddB8EJMBK3UPeN-Vy-c0qFNHyC87muproVpQ';  
                attributes = string(abi.encodePacked(
                    '{"trait_type": "Hacked", "value": "',
                    _rewardClaimed[tokenId] ? "true": "false",
                    '"}'));
                bytes memory byteString = abi.encodePacked(
                    abi.encodePacked(_uriComponents[0], name),
                    abi.encodePacked(_uriComponents[1], description),
                    abi.encodePacked(_uriComponents[2], image),
                    abi.encodePacked(_uriComponents[3], image),
                    abi.encodePacked(_uriComponents[4], animation),
                    abi.encodePacked(_uriComponents[5], animation),
                    abi.encodePacked(_uriComponents[6], attributes),
                    abi.encodePacked(_uriComponents[7])
                );
                return string(byteString);
            }else{
                return string(abi.encodePacked(_uri, Strings.toString(tokenId - _maxSupply), ".json"));
            }
            
        }

    function hack(string calldata password, uint256 tokenId) public {
        require(_exists(tokenId), "claim for nonexistent token");
        require(tokenId < _maxSupply, 'Token not eligible for a claim');
        require(_rewardClaimed[tokenId] == false, 'Reward for this token already claimed');
        require(ERC721A.ownerOf(tokenId) == msg.sender, 'you can only claim a reward for the NFT you own');
        require(keccak256(abi.encodePacked(bytes(password))) == keccak256(abi.encodePacked(_key)), 'Reward for this token already claimed');
        _mint(msg.sender, 1);
        _rewardClaimed[tokenId] = true;

    }

    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external adminRequired {
        _royalties_recipient = _recipient;
        _royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 salePrice) external view returns (address, uint256) {
        if(_royalties_recipient != address(0)){
            return (_royalties_recipient, (salePrice * _royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }

}
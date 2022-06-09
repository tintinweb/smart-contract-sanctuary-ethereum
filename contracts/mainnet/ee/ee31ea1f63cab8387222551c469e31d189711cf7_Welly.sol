// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721A.sol";
import "Ownable.sol";
import "Strings.sol";

struct WLMinter {
    uint _obtained;
    bool _check;
}

enum SaleStatus {
    stopped,
    started,
    killed
}

interface Holder {
    function balanceOf(address owner) external view returns (uint256);
}

interface ShiboshiStakingHolder {
    function lockInfoOf(address user) external view returns(
                                                            uint256[] memory ids,
                                                            uint256 startTime,
                                                            uint256 numDays,
                                                            address ogUser
                                                          );
}

contract Welly is ERC721A, Ownable {
    using Strings for uint256;

    string private baseURI;
    
    uint public max_tokens_per_mint = 10;
    
    uint256 public cost = 0.12 ether;
    
    string private uriPrefix = ".json";
    
    bool private is_revealed = false;
    
    string private not_revealed_uri;

    uint total_tokens = 10000;

    uint wl_remaining_tokens = 1856;

    uint max_wl_balance = 4;

    SaleStatus public _actual_sale_status;

    mapping(address => WLMinter) private _sale_wl;

    uint public sale_start_date;

    address private _shiboshi_contract = 0x11450058d796B02EB53e65374be59cFf65d3FE7f;
    address private _leash_contract = 0x27C70Cd1946795B66be9d954418546998b546634;
    address private _shiboshi_staking_contract = 0xBe4E191B22368bfF26aA60Be498575C477AF5Cc3;
    address private _xleash_contract = 0xa57D319B3Cf3aD0E4d19770f71E63CF847263A0b;

    address private _bone_token_contract = 0x9813037ee2218799597d83D4a5B6F3b6778218d9;
    address private _tbone_staking_contract = 0xf7A0383750feF5AbaCe57cc4C9ff98e3790202b3;
    address private _shiba_token_contract = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address private _xshib_staking_contract = 0xB4a81261b16b92af0B9F7C4a83f1E885132D81e4;

    constructor(string memory _initBaseURI, string memory _not_revealed_uri) ERC721A("Welly Friends", "WELLY") {
        setNotRevealedURI(_not_revealed_uri);
        setBaseURI(_initBaseURI);
    }

    function contractURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmfJawxyaqhCx4XBQTsJiy62h7Pq3dJAAXcZH91EHy3o2e";
    }

    function setIsRevealed(bool _flag) public onlyOwner {
        is_revealed = _flag;
    }

    function setNotRevealedURI(string memory _newRevealedURI) public onlyOwner {
        not_revealed_uri = _newRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSaleStatus(SaleStatus _newStatus) public onlyOwner {
        _actual_sale_status = _newStatus;

        if (_newStatus == SaleStatus.started) {
            sale_start_date = block.timestamp;
        }
    }

    function isSaleWL(address _addr) private view returns(bool) {
        return _sale_wl[_addr]._check;
    }

    function setWhiteLists(address[] memory _addrs) public onlyOwner{
        for (uint i=0; i<_addrs.length; i++) {
            _sale_wl[_addrs[i]] = WLMinter(0, true);
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        if (!is_revealed) {
            return bytes(not_revealed_uri).length > 0 ? string(abi.encodePacked(not_revealed_uri, tokenId.toString(), uriPrefix)) : "";
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), uriPrefix)) : "";
    }

    function isHolderOf(address _contract) private view returns(bool){
        return Holder(_contract).balanceOf(msg.sender) > 0 ? true : false;
    }

    function isShiboshiStaking() private view returns(bool) {
        (uint256[] memory ids, uint256 b, uint256 c, address d) = ShiboshiStakingHolder(_shiboshi_staking_contract).lockInfoOf(msg.sender);
        return ids.length > 0;
    }

    function isFirstPhaseHolder() private view returns(bool) {
        return isHolderOf(_shiboshi_contract) || isHolderOf(_leash_contract) || isShiboshiStaking() || isHolderOf(_xleash_contract);
    }

    function isTokensHolder() private view returns(bool) {
        return isHolderOf(_bone_token_contract) || isHolderOf(_shiba_token_contract) || isHolderOf(_tbone_staking_contract) || isHolderOf(_xshib_staking_contract);
    }

    function mint(uint256 _mintAmount) public payable {

        require(_actual_sale_status == SaleStatus.started, "The sale is not started");
        require(_mintAmount > 0, "Really?");
        require(_mintAmount <= max_tokens_per_mint, "Too many mints!");
        require(totalSupply() < total_tokens, "Sold Out");

        uint _now = block.timestamp;
        
        if(_now > sale_start_date + 2 days) 
            cost = 0.15 ether;

        
        require(msg.value >= cost * _mintAmount, "Insufficient funds");
        

        // Phase 1 (Holders)
        if (_now >= sale_start_date && _now <= sale_start_date + 1 days) 
            firstPhaseMint(_mintAmount, _now);
            
        // Phase 2 (WL)
        if (_now > sale_start_date + 1 days && _now <= sale_start_date + 2 days) 
            secondPhaseMint(_mintAmount);

        // Phase 3 (Public)
        if (_now > sale_start_date + 2 days)
            _safeMint(msg.sender, _mintAmount);
        
    }

    function firstPhaseMint(uint _mintAmount, uint _now) private {
        require(totalSupply() < 8144, "Phase 1 Sold Out");
        // Shiba - Bone token and stakers
        if(_now >= sale_start_date + 12 hours) 
            require(isFirstPhaseHolder() || isTokensHolder(), "You are not whitelisted for this sale");
        else
            require(isFirstPhaseHolder(), "You are not whitelisted for this sale");

        _safeMint(msg.sender, _mintAmount);
    }

    function secondPhaseMint(uint _mintAmount) private {
        require(_mintAmount <= 4, "Too many mints!");
        require(wl_remaining_tokens >= _mintAmount, "Too many mints for the remaining NFTs");
        require(isSaleWL(msg.sender), "You are not whitelisted for this sale");
        require(_sale_wl[msg.sender]._obtained < max_wl_balance, "You have reached the maximum number of mints");
        require(_sale_wl[msg.sender]._obtained + _mintAmount <= max_wl_balance, "Too many mints for the remaining balance");

        _safeMint(msg.sender, _mintAmount);

        _sale_wl[msg.sender]._obtained += _mintAmount;
        wl_remaining_tokens -= _mintAmount;
    }

    function withdraw(address payable recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        recipient.transfer(balance);
    }

}
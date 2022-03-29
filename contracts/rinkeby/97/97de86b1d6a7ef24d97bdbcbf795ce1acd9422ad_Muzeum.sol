// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Muzeum is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public WaitingURI;
    bool public auth;
    uint256 _balance = 0;
    uint256 public _authPrice = 0.0000003 ether;
    uint256 mintIndex;
    uint256 SaledLicense;
    address payable public _owner;
    string public artwork;
    string public baseExtension = ".json";

    struct _Customer {
        address _CustAddr;
        string _name;
        uint256 _AuthTime;
        bool _Auth;
    }

    mapping(address => _Customer) _CustList;
    mapping(uint256 => string) private _tokenURIs;

    constructor(address payable _addr, string memory _artwork, string memory initBaseURI, string memory WaitingAuthUri) ERC721("Mata Mu2eum", "MM") {
        SetURI(initBaseURI);
        SetWaitingAuthURI(WaitingAuthUri);
        _owner = _addr;
        artwork = _artwork;
        auth = false;
        mintIndex = 0;
        SaledLicense = 0;
    }

    function _mint(uint256 Gernerate) public onlyOwner {
        for (uint256 i=0;i<Gernerate;i++) {
            _safeMint(msg.sender, mintIndex);
            mintIndex++;
        }
    }

    function SetURI(string memory _initBaseURI)public onlyOwner {
        baseURI = _initBaseURI;
    }

    function SetWaitingAuthURI(string memory _WaitingURI) public onlyOwner {
        WaitingURI = _WaitingURI;
    }

    function NewAuthPrice(uint256 NewValue) public onlyOwner {
        _authPrice = NewValue;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        /*if (auth == false) {
            return WaitingURI;
        }*/

        if(_CustList[msg.sender]._Auth == false) {
            return WaitingURI;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    function _baseURI()internal view virtual override returns(string memory) {
        return baseURI;
    }

    function RequestForAuth(address _CustomerAddr, string memory _CustomerName) payable public {
        require(msg.value == _authPrice, "The value that you've been payed are the wrong value");
        require(SaledLicense < mintIndex, "There is not enoght License to buy");
        _balance += _authPrice;
        _CustList[_CustomerAddr]._CustAddr = _CustomerAddr;
        _CustList[_CustomerAddr]._name = _CustomerName;
        _CustList[_CustomerAddr]._Auth = false;
        SaledLicense++;
    }

    function Authorize(address _CustomerAddr) public onlyOwner {
        auth = true;
        /* if(_CustList[addr].Auth == true) {
            transferfrom()
        }*/
        _CustList[_CustomerAddr]._Auth = true;
        _CustList[_CustomerAddr]._AuthTime += 1 days;
    }

    function CancelAuth() public onlyOwner {
        auth = false;
        //_CustList[_CustomerAddr]._Auth = false;
    }

    function withdraw(uint256 among) public onlyOwner {
        require(_balance > among, "Invalid among");
        _balance -= among;
        payable(msg.sender).transfer(among);
    }

    fallback() external payable{}
    receive() external payable{}


}
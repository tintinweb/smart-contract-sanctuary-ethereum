// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.12;

import "./ERC1155.sol";
import "./IERC20.sol";
import "./IEIP2981.sol";
import "./AdminControl.sol";
import "./Strings.sol";




contract Duality is ERC1155, AdminControl {
    
    mapping(address => uint256) public _tokensClaimed;
    mapping(address => bool) public _exchanged;

    string private _uri = "https://arweave.net/tGXT29j1OAIPHwJHoxZYA7u9CKPe3ZHSfBWdGZpGx4o/token";
    string private _name = "DUALITY";

    uint256 public _ashPrice = 10*10**18; //10 ASH
    uint256 public _exchangePrice = 5*10**18;
    uint256 private _royaltyAmount; //in % 

    // address _ashContract;
    address public _ashContract = 0x4392329a8565E81E3C041034feAC84616fe9A722;
    // address public _ashContract = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;
    address private _royalties_recipient;
    address private _signer;

    bool public _mintOpened = false;
    bool public _exchangesAllowed = false;
    
    constructor () ERC1155("") {
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
    } 


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AdminControl)
        returns (bool)
    {
        return
        AdminControl.supportsInterface(interfaceId) ||
        ERC1155.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function mintAllowed(uint256 quantity, uint256 ALNumber, uint8 v, bytes32 r, bytes32 s)internal view returns(bool){
        return(
            _signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(
                                abi.encodePacked(
                                    msg.sender,
                                    address(this),
                                    _mintOpened,
                                    quantity <= ALNumber,
                                    ALNumber
                                )
                            )
                        )
                    )
                , v, r, s)
        );
    }

    function setSigner (address signer) external adminRequired{
        _signer = signer;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function publicMint(
        address account,
        uint256[] calldata  tokenIds,
        uint256[] calldata quantities,
        uint256 ALNumber,
        uint8 v,
        bytes32 r, 
        bytes32 s
    ) external {
        uint256 quantity = 0; 
        for(uint256 i = 0 ; i < quantities.length; i++){
            quantity += quantities[i];
        }
        require(mintAllowed(quantity, ALNumber, v, r, s), "Mint not allowed");
        require(_tokensClaimed[account] + quantity <= ALNumber, "Cannot mint more than allowed number of tokens");
        IERC20(_ashContract).transferFrom(msg.sender, _royalties_recipient, _ashPrice * quantity);
        _mintBatch(account ,tokenIds ,quantities ,"0x00");
        _tokensClaimed[account] = _tokensClaimed[account] + quantity;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )external adminRequired{
        _mintBatch(to, ids, amounts, "0x0");
    }

    function toggleMintState()external adminRequired{
        _mintOpened = !_mintOpened;
    }

    function toggleExchangeState()external adminRequired{
        _exchangesAllowed = !_exchangesAllowed;
    }

    function setURI(
        string calldata updatedURI
    ) external adminRequired{
        _uri = updatedURI;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_uri, Strings.toString(tokenId), ".json"));
    }

    function exchange(address account, uint256 token, uint256 newToken) external{
        bool alreadyExchanged = _exchanged[account];
        require(_exchangesAllowed, "Exchange phase closed");
        require(isAdmin(msg.sender) || account == msg.sender,"Cannot exchange another person's token");
        require(balanceOf(account, token)>0, "You do not own this token");
        if(alreadyExchanged){
            IERC20(_ashContract).transferFrom(msg.sender, _royalties_recipient, _exchangePrice);
        }
        _burn(account, token, 1);
        _mint(account, newToken, 1, "0x00");
        if(!alreadyExchanged){
            _exchanged[account] = true;
        }
    }

    function burn(uint256 tokenId, uint256 quantity) public {
        _burn(msg.sender, tokenId, quantity);
    }

    function burnBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    )external{
        _burnBatch(msg.sender, ids, amounts);
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract SmartIntelligenceLicense is ERC721Enumerable, ReentrancyGuard {
    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _price;
    IERC20 private _paymentToken;
    bool private _paused = false;
    mapping(uint256 => SILDetail) public SILDetails;

    event UpdateMintPrice(uint256 oldMintPrice, uint256 newMintPrice);
    event UpdatePause(bool oldVal, bool newVal);
    event UpdatePaymentToken(address oldPaymentToken, address newPaymentToken);
    event NewModelMint(address creator, uint256 price);
    // Model Properties on chain
    struct SILDetail {
        bool enableSale; //Agreement To sell Copyright agreement
        bool enableInvestment; //Allows investors to invest
    }

    constructor(string memory baseURI, uint256 price, address paymentToken)
        ERC721("Smart Intelligence License NFT", "SIL")
    {
        setBaseURI(baseURI);
        _price = price;
        _paymentToken = IERC20(paymentToken);
    }

    // Just in case Payment Token does some crazy stuff
    function setMintPrice(uint256 _newPrice) external onlyOwner {
        require(_price != _newPrice, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        emit UpdateMintPrice(_price, _newPrice);
        _price = _newPrice;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function pause(bool val) public onlyOwner {
        require(_paused != val, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        emit UpdatePause(_paused, val);
        _paused = val;
    }

    function getPause() public view returns(bool) {
        return _paused;
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    function getPaymentToken() external view returns (IERC20) {
        return _paymentToken;
    }

    function setPaymentToken(address _newPaymentToken) external onlyOwner {
        require(_newPaymentToken != address(_paymentToken), "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        emit UpdatePaymentToken(address(_paymentToken), _newPaymentToken);
        _paymentToken = IERC20(_newPaymentToken);
    }

    function adopt(SILDetail calldata _SILDetail) public nonReentrant{
        uint256 supply = totalSupply();
        require(!_paused, "Sale is not active currently.");
        require(
            _paymentToken.balanceOf(msg.sender) >= _price,
            "The ERC20 token amount sent is not correct or Insuffient ERC20 Token amount sent."
        );

        SILDetails[supply + 1] = _SILDetail;

        _paymentToken.transferFrom(msg.sender, address(this), _price);


        _safeMint(msg.sender, supply + 1);

        emit NewModelMint(msg.sender, _price);

    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getMintPrice() public view returns (uint256) {
        return _price;
    }

    function withdraw(uint256 _amount, IERC20 _token) external onlyOwner {
        require(
            _amount <= _token.balanceOf(address(this)),
            "Not enough balance!"
        );

        _token.transfer(_msgSender(), _amount);
    }

    function setSILDetail(SILDetail calldata _SILDetail, uint256 _tokenId)
        external
    {
        require(ownerOf(_tokenId) == _msgSender(), "Only ownenr can access!");
        require(
            _SILDetail.enableInvestment !=
                SILDetails[_tokenId].enableInvestment ||
                _SILDetail.enableSale != SILDetails[_tokenId].enableSale,
            "Changed as you want already!"
        );
        
        SILDetails[_tokenId] = _SILDetail;
    }

}
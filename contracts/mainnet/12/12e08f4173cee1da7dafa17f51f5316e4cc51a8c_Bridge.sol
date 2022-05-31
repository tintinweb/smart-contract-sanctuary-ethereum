/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a), 'mul overflow');
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a),
            'sub overflow');
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a),
            'add overflow');
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256,
            'abs overflow');
        return a < 0 ? -a : a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,
            'parameter 2 can not be 0');
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function totalSupply () external view returns (uint256);
    function mintspecificNFTs (uint8 _quantity, uint256 [] memory _randomNumber) external;
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event TransferOwnerShip(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Not owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit TransferOwnerShip(newOwner);
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),
            'Owner can not be 0');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Bridge is Ownable {

    using SafeMath for uint256;
    using SafeMathInt for int256;

    uint256 public fees;
    address public tokenAddress;
    address public nftAddress;

    mapping (address => bool) public isAuthorized;
    mapping (address => mapping (uint256 => bool)) public feesPaid;

    constructor () {}

    modifier authorized {
        require (isAuthorized[msg.sender], "You are not authorized to do this action");
        _;
    }

    function setFees (uint256 _fees) public onlyOwner {
        fees = _fees;
    }

    function setTokenAddress (address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setNftAddress (address _nftAddress) public onlyOwner {
        nftAddress = _nftAddress;
    }

    function setAuthorized (address _address, bool _isAuthorized) public onlyOwner {
        isAuthorized[_address] = _isAuthorized;
    }

    function setFeesPaid (address _recipient, uint256 _nftId, bool _paid) public onlyOwner {
        feesPaid[_recipient][_nftId] = _paid;
    }

    // will be used to check for supplying the Nft in any chain
    function shouldSupply (address _recipient, uint256 _nftId) public view returns (bool) {
        IERC721 nft = IERC721(nftAddress);
        if (nft.ownerOf(_nftId)== address(this) && feesPaid[_recipient][_nftId]) return true;
        return false;
    }

    // this function is to withdraw BNB sent to this address by mistake
    function withdrawEth () external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: balance
        }("");
        return success;
    }

    // this function is to withdraw extra tokens locked in the contract.
    function withdrawLockedTokens (address _tokenAddress) external onlyOwner returns (bool) {
        IBEP20 token = IBEP20 (_tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        bool success = token.transfer(msg.sender, balance);
        return success;
    }

    // this function is to withdraw extra NFTs locked in the contract.
    function withdrawLockedNfts (uint256 _nftId) external onlyOwner returns (bool) {
        IERC721 nft = IERC721(nftAddress);
        nft.transferFrom(address(this), msg.sender, _nftId);
        return true;
    }

    function lockNft (uint256 _nftId) public {
        if (fees > 0){
            IBEP20 token = IBEP20 (tokenAddress);
            bool success = token.transferFrom(msg.sender, address(this), fees);
            require(success, "Taking fees failed");
        }
        feesPaid[msg.sender][_nftId] = true;
        IERC721 nft = IERC721(nftAddress);
        nft.transferFrom(msg.sender, address(this), _nftId);
    }

    function supplyNft (address _recipient, uint256 _nftId, uint256 _randomNumber) public authorized {
        feesPaid[_recipient][_nftId] = false;
        IERC721 nft = IERC721(nftAddress);
        uint256 _totalSupply = nft.totalSupply();
        if ( _totalSupply < _nftId) {
            uint256[] memory _temp = new uint256[](1);
            _temp[0]= _randomNumber;
            nft.mintspecificNFTs(1, _temp);
        }
        nft.transferFrom(address(this), _recipient, _nftId);
    }
}
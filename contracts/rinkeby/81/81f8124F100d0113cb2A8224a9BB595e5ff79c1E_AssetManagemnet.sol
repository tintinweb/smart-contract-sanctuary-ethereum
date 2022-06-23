// SPDX-License-Identifier: MIT
import "./AccessControl.sol";
import "./ECDSA.sol";
import "./SignatureChecker.sol";
import {Types} from "./Types.sol";

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

   
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function changePaused() external;

    function mint(address to,uint256 tokenId,string calldata uri) external;

    function burn(address user,uint256 tokenId) external;

    function transferOwnership(address newOwner) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}





interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals()  view external returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}






 

contract AssetManagemnet is AccessControl {
    using SafeMath for uint256;
    using Types for Types.Sign;
    mapping(uint256 => bool) public nonces;
    bytes32 public constant OPERATORROLE = keccak256("OPERATORROLE");


    mapping(address => bool) public activeTokens;
    address[]  private contracts; 
    mapping(address => bool) public signers;
    mapping(address => bool) public users;


    address public WETH;
    address public BANKCARDNFT;


    uint256 public lastTokenId;

	bytes32 public immutable DOMAIN_SEPARATOR;

    event Deposit(address sender, address token, uint256 value);
    event DepositForRepay(address sender, address token, uint256 value);
    event Widthdraw(address signer,address reciver, address token, uint256 value,string  functionName);
    event WidthdrawETH(address signer,address reciver, uint256 value,string  functionName);
    event ActiveToken(address token);
    event PauseToken(address token);
    event ChangeSigner(address signer,bool flag);
    event FeeChange(uint256 fee);


    constructor (address _weth,address _bankCardNFT) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(OPERATORROLE, msg.sender);
        activeTokens[_weth] = true;
        contracts.push(_weth);
        WETH = _weth;
        BANKCARDNFT = _bankCardNFT;
        // Calculate the domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0xb03948446334eb9b2196d5eb166f69b9d49403eb4a12f36de8d3f9f3cb8e15c3, // keccak256("EIP712Domain(string name,string version)")
                0xf1e6b9a4cc25fff18abd63bc624fb1f74b1cd01e767ae9de37b766eb37a90420, // keccak256("Sign")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6 // keccak256(bytes("1")) for versionId = 1
            )
        );     
    }


    function deposit(
        address token,
        uint256 amount
    ) external {
        require(amount > 0, 'Deposit: amount can not be 0');
        require(activeTokens[token], 'Deposit: token not support');
        IERC20(token).transferFrom(msg.sender,address(this),amount);
        emit Deposit(msg.sender, token,amount);
    }

    function depositForRepay(
        address token,
        uint256 amount
    ) external {
        require(amount > 0, 'DepositForRepay: amount can not be 0');
        require(activeTokens[token], 'DepositForRepay: token not support');
        IERC20(token).transferFrom(msg.sender,address(this),amount);
        emit DepositForRepay(msg.sender,token,amount);
    }

    function depositETHForRepay( ) external payable {
        require(msg.value > 0, 'DepositETHForRepay: amount  zero');
        IWETH(WETH).deposit{value: msg.value}();
        emit DepositForRepay(msg.sender,WETH,msg.value);
    }

     function depositETH() external payable {
        require(msg.value > 0, 'DepositETH: amount  zero');
        IWETH(WETH).deposit{value: msg.value}();
        emit Deposit(msg.sender,WETH,msg.value);
    }

    function depositETHWithNFT(
        uint256 nonce,
        string memory tokenUri,
        uint8 v,
        bytes32 r,
        bytes32 s
     ) external payable {
        require(msg.value > 0, 'DepositETHWithETH: amount can not be 0');
        require(!nonces[nonce], 'DepositETHWithETH: nonce had used');
        bytes32 hash = keccak256(abi.encode(msg.sender,msg.value,nonce,tokenUri));
        address signer = ECDSA.recover(hash, v, r, s);
        require(signers[signer], 'DepositETHWithETH: signature error');
        lastTokenId +=1;
        nonces[nonce] = true;
        _mintNFT(msg.sender,lastTokenId,tokenUri);
        IWETH(WETH).deposit{value: msg.value}();
        emit Deposit(msg.sender,WETH,msg.value);
    }

    function depositWithNFT(
        address token,
        uint256 amount,
        uint256 nonce,
        string memory tokenUri,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, 'DepositWithNFT: amount can not be 0');
        require(activeTokens[token], 'DepositWithNFT: token not support');
        require(!nonces[nonce], 'DepositWithNFT: nonce had used');
        bytes32 hash = keccak256(abi.encode(msg.sender,token,amount,nonce,tokenUri));
        address signer = ECDSA.recover(hash, v, r, s);
        require(signers[signer], 'Claim: signature error');
        lastTokenId +=1;
        nonces[nonce] = true;
        _mintNFT(msg.sender,lastTokenId,tokenUri);
        IERC20(token).transferFrom(msg.sender,address(this),amount);
        emit Deposit(msg.sender, token,amount);
    }

    function withdraw(Types.Sign memory sign,address token) public {
        require(hasRole(OPERATORROLE, msg.sender), "Caller is not a operator");
        _validateSign(sign);
        IERC20(token).transfer(sign.toUser,sign.amount);
        emit Widthdraw(sign.signer,sign.toUser,token,sign.amount,sign.functionName);

    }

    function withdrawETH(Types.Sign memory sign) public {
        require(hasRole(OPERATORROLE, msg.sender), "Caller is not a operator");
        _validateSign(sign);
        IWETH(WETH).withdraw(sign.amount);
        _safeTransferETH(sign.toUser, sign.amount);
        emit WidthdrawETH(sign.signer,sign.toUser,sign.amount,sign.functionName);

    }

    function activeToken(address token) external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        require(!activeTokens[token], 'AddToken: token already supported');
        contracts.push(token);
        activeTokens[token] = true;   
        emit ActiveToken(token);
    }

    function addSigner(address signer) external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        signers[signer] = true;  
        emit ChangeSigner(signer,true);
    }

    function removeSigner(address signer) external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        signers[signer] = false;  
        emit ChangeSigner(signer,false);
    }

    function pauseToken(address token) external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        require(activeTokens[token], 'PauseToken: token not active');
        activeTokens[token] = false;
        emit PauseToken(token);
    }

    function burnNFT(address user,uint256 tokenId) external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        IERC721(BANKCARDNFT).burn(user,tokenId);
    }

    function changePaused() external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        IERC721(BANKCARDNFT).changePaused();
    }


    function supportTokens() public view returns (address[] memory) {
        return contracts;  
    }


  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }


  function _mintNFT(address to, uint256 tokenId,string memory tokenUri) internal {
      IERC721(BANKCARDNFT).mint(to,tokenId,tokenUri);
    
  }

  fallback() external payable {
    revert('Fallback not allowed');
  }

  /**
   * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
   */
  receive() external payable {
    require(msg.sender == address(WETH), 'Receive not allowed');
  }

  function _validateSigner(bytes32 hash,address signer,uint8 v,bytes32 r,bytes32 s ) internal view {
        
       
        require(
            SignatureChecker.verify(
                hash,
                signer,
                v,
                r,
                s,
                DOMAIN_SEPARATOR
            ),
            "Signature: Invalid"
        );
    }

    function _validateSign(Types.Sign memory sign) internal {
        require(sign.amount > 0, 'Sign: nothing to send');
        require(!nonces[sign.nonce], 'Sign: nonce had used');
		bytes32 signHash = sign.hashSign();
		_validateSigner(signHash, sign.signer,sign.v,sign.r,sign.s);
        nonces[sign.nonce] = true;
    }

   




 


}
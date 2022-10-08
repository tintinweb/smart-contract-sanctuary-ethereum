// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/Coffer.sol";
import "./lib/FixedAssertsFactory.sol";
import "./lib/BatchMint.sol";

contract FixedAssertsSetUpWithManager{
    event SetUp(address coffer, address fixedAssertsFactory, address batchMint);
    constructor(address manager){
        Coffer coffer = new Coffer();
        FixedAssertsFactory fixedAssertsFactory = new FixedAssertsFactory(address(coffer));
        BatchMint batchMint = new BatchMint();
        coffer.transferManagership(manager);
        fixedAssertsFactory.transferManagership(manager);

        emit SetUp(address(coffer), address(fixedAssertsFactory), address(batchMint));

        selfdestruct(payable(msg.sender));
    }
}

contract FixedAssertsSetUp{
    event SetUp(address coffer, address fixedAssertsFactory, address batchMint);
    constructor(){
        Coffer coffer = new Coffer();
        FixedAssertsFactory fixedAssertsFactory = new FixedAssertsFactory(address(coffer));
        BatchMint batchMint = new BatchMint();

        emit SetUp(address(coffer), address(fixedAssertsFactory), address(batchMint));

        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

contract BatchMint is ReentrancyGuard {

    event BatchCast(uint256[] orderIds);

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _trade(
        address NFT,
        uint256 value,
        bytes calldata tradeData
    ) internal returns (bool){
        // execute trade
        (bool success,) = NFT.call{value : value}(tradeData);

        return success;
    }


    function batchMint(
        address[] calldata NFTAddrs,
        uint256[] calldata values,
        bytes[] calldata tradeDatas,
        bool revertIfTrxFail
    ) payable external nonReentrant {
        uint256 len = NFTAddrs.length;
        require(len == tradeDatas.length && len == values.length, "LENGTH_MISMATCH");

        uint256[] memory successIds = new uint256[](len);
        uint256 index;

        for (uint256 i = 0; i < len; ++i) {

            address NFTAddr = NFTAddrs[i];
            bytes calldata tradeData = tradeDatas[i];
            uint256 value = values[i];

            bool _success = _trade(NFTAddr, value, tradeData);

            if (_success) {
                successIds[index++] = i + 1;
            } else if (revertIfTrxFail == true) {
                _checkCallResult(_success);
            }
        }


        assembly{
            mstore(successIds, index)
            if gt(selfbalance(), 0) {
                let callStatus := call(
                gas(),
                caller(),
                selfbalance(),
                0,
                0,
                0,
                0
                )
            }
        }

        emit BatchCast(successIds);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FixedAsserts.sol";
import "./Manageable.sol";
import "./Ecrecovery.sol";
import "../interfaces/ICoffer.sol";
import "../interfaces/IFixedAssertsFactory.sol";

contract FixedAssertsFactory is IFixedAssertsFactory, Manageable {

    using Strings for uint256;

    using Strings for address;

    // Accuracy of loan charge ratio
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    address public coffer;

    mapping(string => ICoffer.Receipt) private receipts;


    constructor(address newCoffer){
        setCoffer(newCoffer);
    }

    function getCreationBytecode(
        FixedAssertStructs.Assert memory newAssert
    )
    internal
    pure
    returns (bytes memory) {
        bytes memory bytecode = type(FixedAsserts).creationCode;

        return abi.encodePacked(bytecode, abi.encode(newAssert));
    }

    function getAssertsAddr(
        FixedAssertStructs.Assert memory newAssert
    )
    internal
    view
    returns (address assertsAddress) {

        bytes32 salt = keccak256(abi.encodePacked(address(this), msg.sender, newAssert.baseURI));
        bytes memory creationBytecode = getCreationBytecode(newAssert);

        assertsAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(creationBytecode)
            )))));
    }

    function newAsserts(
        string calldata businessId,
        string[] calldata baseInfo,
        uint256 totalSupply_,
        address feeToken,
        uint256 feeAmount,
        uint256 loanRatio,
        uint256 repurchaseRatio,
        uint256 repurchasePeriod,
        bytes calldata managerSign
    )
    public
    payable
    returns (address) {

        FixedAssertStructs.Assert memory newAssert;
        newAssert.name = baseInfo[0];
        newAssert.symbol = baseInfo[1];
        newAssert.baseURI = baseInfo[2];
        newAssert.totalSupply = totalSupply_;
        newAssert.loanRatio = loanRatio;
        newAssert.repurchaseRatio = repurchaseRatio;
        newAssert.repurchasePeriod = repurchasePeriod;
        newAssert.coffer = coffer;
        newAssert.factory = address(this);
        newAssert.owner = msg.sender;

        FixedAssertStructs.Charge memory chargeFee;
        chargeFee.businessId = businessId;

        chargeFee.feeToken = feeToken;
        chargeFee.feeAmount = feeAmount;

        bytes32 hash = managerSignHash(newAssert, chargeFee);
        require(manager() == Ecrecovery.ecrecovery(hash, managerSign), "Manager signature error");

        require(bytes(newAssert.baseURI).length != 0, "BaseURI cannot be empty");

        address assertsAddr = getAssertsAddr(newAssert);
        require(assertsAddr.codehash == bytes32(0), "The new contract address has been deployed");

        bytes32 salt = keccak256(abi.encodePacked(address(this), msg.sender, newAssert.baseURI));

        FixedAsserts asserts = new FixedAsserts{salt : salt}(newAssert);

        chargeFee.asserts = address(asserts);

        require(charge(chargeFee), "Charge deployment fee failed");

        return address(asserts);
    }


    function setCoffer(
        address newCoffer
    )
    public
    onlyOwner {
        address oldCoffer = coffer;
        coffer = newCoffer;
        emit CofferChanged(oldCoffer, newCoffer);
    }

    function charge(
        FixedAssertStructs.Charge memory chargeFee
    )
    internal
    returns (bool) {

        ICoffer.Receipt storage receipt;
        string memory receiptNum = string(abi.encodePacked(address(this).toHexString(), "#", uint256(uint160(chargeFee.asserts)).toString()));
        receipt = receipts[receiptNum];
        receipt.receiptNum = receiptNum;
        receipt.operator = tx.origin;
        receipt.NFTAddr = address(this);
        receipt.NFTId = uint256(uint160(chargeFee.asserts));
        receipt.tokenAddr = chargeFee.feeToken;
        receipt.tokenAmount = chargeFee.feeAmount;
        receipt.timestamp = block.timestamp;

        if (chargeFee.feeToken == address(0)) {
            require(msg.value >= chargeFee.feeAmount, "Insufficient ETH fee");
            payable(address(coffer)).transfer(chargeFee.feeAmount);
            require(ICoffer(coffer).sendReceipt(receipt), "Receipt sending failed");

            assembly{
                if gt(selfbalance(), 0) {
                    let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                    )
                }
            }

        } else {
            IERC20 token = IERC20(chargeFee.feeToken);
            uint256 amount = token.allowance(msg.sender, address(this));
            if (amount < chargeFee.feeAmount) {
                revert("Insufficient ERC20 approve");
            } else {
                bool success = token.transferFrom(msg.sender, address(coffer), chargeFee.feeAmount);
                require(success, "ERC20 transferFrom fail");
                require(ICoffer(coffer).sendReceipt(receipt), "Receipt sending failed");
            }
        }
        emit NewAsserts(chargeFee.businessId, chargeFee.asserts, address(coffer), receipt.receiptNum, receipt.operator, receipt.NFTAddr, receipt.NFTId, receipt.tokenAddr, receipt.tokenAmount, receipt.timestamp);
        return true;
    }

    function checkReceipt(string memory receiptNum_)
    public
    view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 serviceFee,
        uint256 timestamp
    ){
        ICoffer.Receipt memory receipt = receipts[receiptNum_];
        receiptNum = receipt.receiptNum;
        operator = receipt.operator;
        NFTAddr = receipt.NFTAddr;
        NFTId = receipt.NFTId;
        tokenAddr = receipt.tokenAddr;
        tokenAmount = receipt.tokenAmount;
        serviceFee = receipt.serviceFee;
        timestamp = receipt.timestamp;
    }

    function managerSignHash(
        FixedAssertStructs.Assert memory newAssert,
        FixedAssertStructs.Charge memory ChargeFee
    )
    internal
    view
    returns (bytes32 hash){
        bytes memory message = abi.encode(newAssert.name, newAssert.symbol, newAssert.baseURI, newAssert.totalSupply, newAssert.loanRatio, newAssert.repurchaseRatio, newAssert.repurchasePeriod, ChargeFee.feeToken, ChargeFee.feeAmount, msg.sender);
        hash = keccak256(message);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Manageable.sol";
import "../interfaces/ICoffer.sol";
import "../interfaces/IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Ecrecovery.sol";

contract Coffer is ICoffer, Manageable, ReentrancyGuard {

    using Strings for uint256;

    using Strings for address;

    mapping(string => bool) private businessBook;

    mapping(string => Receipt) private receipts;

    mapping(address => uint256) public balanceOf;

    constructor(){

    }

    receive() payable external {}

    fallback() payable external {}

    function sendReceipt(
        Receipt calldata receipt
    )
    public
    nonReentrant
    returns (bool){
        require(receipt.NFTAddr == msg.sender, "Caller must be NFT contract");
        bytes32 _receiptNumHash = keccak256(abi.encodePacked(receipt.NFTAddr.toHexString(), "#", receipt.NFTId.toString()));
        bytes32 receiptNumHash = keccak256(abi.encodePacked(receipt.receiptNum));
        require(_receiptNumHash == receiptNumHash, "Receipt source unknown");
        require(bytes(receipts[receipt.receiptNum].receiptNum).length == 0, "This receipt has been stored");
        uint256 balanceBefor = balanceOf[receipt.tokenAddr];
        uint256 balanceNow;
        if (receipt.tokenAddr != address(0)) {
            IERC20 token = IERC20(receipt.tokenAddr);
            balanceNow = token.balanceOf(address(this));
        } else {
            balanceNow = address(this).balance;
        }
        require(balanceNow >= balanceBefor + (receipt.tokenAmount + receipt.serviceFee), "Token not received");
        balanceOf[receipt.tokenAddr] = balanceNow;
        receipts[receipt.receiptNum] = receipt;
        emit ReceiptReceived(receipt.receiptNum);
        return true;
    }


    function managerWithdraw(
        string memory businessId,
        address payable payee,
        address tokenAddr,
        uint256 amount
    )
    public
    onlyManager
    nonReentrant
    returns (bool){
        if (businessBook[businessId] == true) revert("Withdraw invalid");
        if (tokenAddr == address(0)) {//withdraw ETH
            require(address(this).balance >= amount, "Insufficient ETH");
            businessBook[businessId] = true;
            payee.transfer(amount);
            balanceOf[tokenAddr] -= amount;
            emit Withdraw(businessId, payee, tokenAddr, amount);
            return true;
        } else {//withdraw ERC20
            IERC20 token = IERC20(tokenAddr);
            require(token.balanceOf(address(this)) >= amount, "Insufficient ERC20");
            businessBook[businessId] = true;
            require(token.transfer(payee, amount) == true, "transfer ERC20 fail");
            balanceOf[tokenAddr] -= amount;
            emit Withdraw(businessId, payee, tokenAddr, amount);
            return true;
        }
    }

    function userWithdraw(
        string memory businessId,
        address payable payee,
        address tokenAddr,
        uint256 amount,
        bytes memory sign
    )
    public
    nonReentrant
    returns (bool){
        verify(businessId, tokenAddr, amount, payee, sign);
        if (businessBook[businessId] == true) revert("Withdraw invalid");
        if (tokenAddr == address(0)) {//withdraw ETH
            require(address(this).balance >= amount, "Insufficient ETH");
            businessBook[businessId] = true;
            payee.transfer(amount);
            balanceOf[tokenAddr] -= amount;
            emit Withdraw(businessId, payee, tokenAddr, amount);
            return true;
        } else {//withdraw ERC20
            IERC20 token = IERC20(tokenAddr);
            require(token.balanceOf(address(this)) >= amount, "Insufficient ERC20");
            businessBook[businessId] = true;
            require(token.transfer(payee, amount) == true, "transfer ERC20 fail");
            balanceOf[tokenAddr] -= amount;
            emit Withdraw(businessId, payee, tokenAddr, amount);
            return true;
        }

    }

    function verify(
        string memory businessId,
        address tokenAddr,
        uint256 amount,
        address payable payee,
        bytes memory sign
    )
    internal
    view
    returns (bool) {
        bytes memory message = abi.encode(businessId, tokenAddr, amount, payee, msg.sender);
        bytes32 hash = keccak256(message);
        address _address = Ecrecovery.ecrecovery(hash, sign);
        require(manager() == _address, "illegal signature");
        return true;
    }

    function checkReceipt(string memory receiptNum_)
    public
    view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 serviceFee,
        uint256 timestamp
    ){
        Receipt memory receipt = receipts[receiptNum_];
        receiptNum = receipt.receiptNum;
        operator = receipt.operator;
        NFTAddr = receipt.NFTAddr;
        NFTId = receipt.NFTId;
        tokenAddr = receipt.tokenAddr;
        tokenAmount = receipt.tokenAmount;
        serviceFee = receipt.serviceFee;
        timestamp = receipt.timestamp;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/FixedAssertStructs.sol";

interface IFixedAssertsFactory {

    event CofferChanged(address oldCoffer, address newCoffer);

    event NewAsserts(string businessId, address asseryContractAddr, address coffer, string receiptNum, address operator, address NFTAddr, uint256 NFTId, address tokenAddr, uint256 tokenAmount, uint256 timestamp);

    function newAsserts(
        string calldata businessId,
        string[] calldata baseInfo,
        uint256 totalSupply_,
        address feeToken,
        uint256 feeAmount,
        uint256 loanRatio,
        uint256 repurchaseRatio,
        uint256 repurchasePeriod,
        bytes calldata managerSign
    )
    external
    payable
    returns (address);

    function setCoffer(
        address newCoffer
    )
    external;


    function checkReceipt(string memory receiptNum_)
    external
    view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 serviceFee,
        uint256 timestamp
    );


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/CofferStructs.sol";

interface ICoffer is CofferStructs {

    event ReceiptReceived(string receiptNum);

    event ManagerChanged(address oldManager, address newManager);

    event Withdraw(string serialNum, address payee, address tokenAddr, uint256 amount);


    function sendReceipt(
        Receipt calldata receipt
    ) external returns (bool);


    function managerWithdraw(
        string memory businessId,
        address payable payee,
        address tokenAddr,
        uint256 amount
    ) external returns (bool);

    function userWithdraw(
        string memory businessId,
        address payable payee,
        address tokenAddr,
        uint256 amount,
        bytes memory sign
    ) external returns (bool);


    function checkReceipt(string memory receiptNum_)
    external
    view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 slipPoint,
        uint256 timestamp
    );


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Ecrecovery{

function ecrecovery(
        bytes32 hash,
        bytes memory sig
    )
    internal
    pure
    returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        /* prefix might be needed for geth only
        * https://github.com/ethereum/go-ethereum/issues/3731
        */
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        bytes32 Hash = keccak256(abi.encodePacked(prefix, hash));

        return ecrecover(Hash, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Manageable is Ownable {
    address private _manager;

    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    constructor() {
        _transferManagership(_txOrigin());
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        _checkManager();
        _;
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if the sender is not the manager.
     */
    function _checkManager() internal view virtual {
        require(manager() == _txOrigin(), "Managerable: caller is not the manager");
    }

    /**
     * @dev Transfers managership of the contract to a new account (`newManager`).
     * Can only be called by the current owner.
     */
    function transferManagership(address newManager) public virtual onlyOwner {
        require(newManager != address(0), "Managerable: new manager is the zero address");
        _transferManagership(newManager);
    }

    /**
     * @dev Transfers Managership of the contract to a new account (`newManager`).
     * Internal function without access restriction.
     */
    function _transferManagership(address newManager) internal virtual {
        address oldManager = _manager;
        _manager = newManager;
        emit ManagershipTransferred(oldManager, newManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "../interfaces/ICoffer.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IFixedAsserts.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./FixedAssertStructs.sol";
import "./Ecrecovery.sol";

contract FixedAsserts is ERC721, IFixedAsserts {

    using Strings for uint256;

    using Strings for address;

    // Accuracy of loan charge ratio
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    address public coffer;

    address public factory;

    address public owner;

    string public baseURI;

    uint256 public supply;

    uint256 public totalSupply;

    bytes32 public priceRoot;

    uint256 public loanRatio;

    uint256 public repurchaseRatio;

    uint256 private creationDate;

    uint256 private repurchasePeriod;

    mapping(uint256 => price) private prices;

    mapping(string => ICoffer.Receipt) private receipts;

    modifier onlyOwner(){
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        FixedAssertStructs.Assert memory newAssert
    ) ERC721(newAssert.name, newAssert.symbol){
        totalSupply = newAssert.totalSupply;
        coffer = newAssert.coffer;
        factory = newAssert.factory;
        owner = newAssert.owner;
        baseURI = newAssert.baseURI;
        creationDate = block.timestamp;
        loanRatio = newAssert.loanRatio;
        repurchaseRatio = newAssert.repurchaseRatio;
        repurchasePeriod = newAssert.repurchasePeriod * 24 * 60 * 60;
    }

    function _baseURI(

    )
    internal
    view
    virtual
    override
    returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    )
    public
    view
    virtual
    override(ERC721, IERC721Metadata)
    returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, "/", tokenId.toString())) : "";
    }

    function setPriceRoot(
        bytes32 newPriceRoot
    )
    public onlyOwner {
        bytes32 oldPriceRoot = priceRoot;
        priceRoot = newPriceRoot;
        emit PriceRootChanged(oldPriceRoot, newPriceRoot);
    }


    function mint(
        uint256 tokenId,
        address feeToken,
        uint256 feeAmount,
        uint256 serviceFee,
        bytes calldata managerSign,
        bytes32[] calldata proof
    )
    public
    payable {
        FixedAssertStructs.Token memory token;
        token.to = tx.origin;
        token.tokenId = tokenId;
        token.feeToken = feeToken;
        token.feeAmount = feeAmount;
        token.serviceFee = serviceFee;

        bytes32 hash = managerSignHash(token);
        (bool success, bytes memory data) = factory.call(abi.encodeWithSignature("manager()"));
        require(success);
        address manager = abi.decode(data, (address));
        require(manager == Ecrecovery.ecrecovery(hash, managerSign), "Manager signature error");

        require(_verify(_leaf(token), proof), "Invalid merkle proof");

        _mint(tx.origin, tokenId);

        ++supply;

        require(charge(token), "Charge mint fee failed");

    }


    function _leaf(
        FixedAssertStructs.Token memory token
    )
    internal
    view
    returns (bytes32) {
        return keccak256(abi.encode(address(this), token.tokenId, token.feeAmount));
    }

    // Test case
    /*
    [
    "0xecc1f48b4e2756e631d9ed25d3ab9b278a9014b0caceb213b8901633d7a8478a",
    "0xba476345fdc95da5d28fc0c3c6e08b84587d931539c4eabf545349e40187e717",
    "0xbd57d6cdcc37b8417b8bc81f5f11a25291ea8c2bb8036592d8188681b086f4ed",
    "0x83781bca6945a929f22ebcaf901c62882a1accb53856d6095287b90a8eb2e437",
    "0xf1d9886d3c59cd6c7d412f803f9c97209bc960885ede16c52230c6a2663b1c86"
    ]
    */
    // https://lab.miguelmota.com/merkletreejs/example/
    // Hash function : Keccak-256
    // Options : sortPairs
    function _verify(
        bytes32 leaf,
        bytes32[] calldata proof
    )
    internal
    view
    returns (bool)
    {
        return MerkleProof.verifyCalldata(proof, priceRoot, leaf);
    }


    function burn(
        uint256 id
    ) external {
        require(ownerOf(id) == msg.sender, "Not your token");
        super._burn(id);
    }

    function charge(
        FixedAssertStructs.Token memory token
    )
    internal
    returns (bool) {

        ICoffer.Receipt storage receipt;
        string memory receiptNum = string(abi.encodePacked(address(this).toHexString(), "#", token.tokenId.toString()));
        receipt = receipts[receiptNum];
        receipt.receiptNum = receiptNum;
        receipt.operator = tx.origin;
        receipt.NFTAddr = address(this);
        receipt.NFTId = token.tokenId;
        receipt.tokenAddr = token.feeToken;
        receipt.tokenAmount = token.feeAmount;
        receipt.serviceFee = token.serviceFee;
        receipt.timestamp = block.timestamp;

        if (token.feeToken == address(0)) {
            require(msg.value >= (token.feeAmount + token.serviceFee), "Insufficient ETH fee");
            payable(address(coffer)).transfer(token.feeAmount + token.serviceFee);
            require(ICoffer(coffer).sendReceipt(receipt), "Receipt sending failed");
        } else {
            IERC20 ERC20Token = IERC20(token.feeToken);
            uint256 amount = ERC20Token.allowance(tx.origin, address(this));
            if (amount < (token.feeAmount + token.serviceFee)) {
                revert("Insufficient ERC20 approve");
            } else {
                bool success = ERC20Token.transferFrom(tx.origin, address(coffer), (token.feeAmount + token.serviceFee));
                require(success, "ERC20 transferFrom fail");
                require(ICoffer(coffer).sendReceipt(receipt), "Receipt sending failed");
            }
        }

        prices[token.tokenId].tokenAddr = token.feeToken;
        prices[token.tokenId].tokenAmount = token.feeAmount;

        emit Cast(tx.origin, address(coffer), receipt.receiptNum, receipt.operator, receipt.NFTAddr, receipt.NFTId, receipt.tokenAddr, receipt.tokenAmount, receipt.serviceFee, receipt.timestamp);
        return true;
    }


    function leafHelper(
        uint256 tokenId,
        uint256 feeAmount
    )
    public
    view
    returns (bytes32) {
        return keccak256(abi.encode(address(this), tokenId, feeAmount));
    }

    function checkRepurchaseDeadline()
    public
    view
    returns (
        uint256 deadline
    ){
        return creationDate + repurchasePeriod;
    }


    function checkPrice(uint256 tokenId)
    public
    view
    returns (
        address tokenAddr,
        uint256 tokenAmount
    ){
        return (prices[tokenId].tokenAddr, prices[tokenId].tokenAmount);
    }


    function checkReceipt(string memory receiptNum_)
    public
    view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 serviceFee,
        uint256 timestamp
    ){
        ICoffer.Receipt memory receipt = receipts[receiptNum_];
        receiptNum = receipt.receiptNum;
        operator = receipt.operator;
        NFTAddr = receipt.NFTAddr;
        NFTId = receipt.NFTId;
        tokenAddr = receipt.tokenAddr;
        tokenAmount = receipt.tokenAmount;
        serviceFee = receipt.serviceFee;
        timestamp = receipt.timestamp;
    }

    function managerSignHash(
        FixedAssertStructs.Token memory token
    )
    internal
    view
    returns (bytes32 hash){
        bytes memory message = abi.encode(token.to, address(this), token.tokenId, token.feeToken, token.feeAmount, token.serviceFee, tx.origin);
        hash = keccak256(message);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_txOrigin());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _txOrigin(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FixedAssertStructs {

    struct Assert {
        string name;
        string symbol;
        string baseURI;
        uint256 totalSupply;
        uint256 loanRatio;
        uint256 repurchaseRatio;
        uint256 repurchasePeriod;
        address coffer;
        address factory;
        address owner;
    }

    struct Token {
        address to;
        uint256 tokenId;
        address feeToken;
        uint256 feeAmount;
        uint256 serviceFee;
    }

    struct Charge {
        string businessId;
        address asserts;
        address feeToken;
        uint256 feeAmount;
    }

    struct price {
        address tokenAddr;
        uint256 tokenAmount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/FixedAssertStructs.sol";
import "./IERC721Metadata.sol";

interface IFixedAsserts is FixedAssertStructs, IERC721Metadata {

    event Cast(address initialOwner, address coffer, string receiptNum, address operator, address NFTAddr, uint256 NFTId, address tokenAddr, uint256 tokenAmount, uint256 serviceFee, uint256 timestamp);

    event PriceRootChanged(bytes32 oldPriceRoot, bytes32 newPriceRoot);

    function setPriceRoot(
        bytes32 newPriceRoot
    ) external;


    function mint(
        uint256 tokenId,
        address feeToken,
        uint256 feeAmount,
        uint256 serviceFee,
        bytes calldata managerSign,
        bytes32[] calldata proof
    ) external payable;


    function leafHelper(
        uint256 tokenId,
        uint256 feeAmount
    ) external view returns (bytes32);

    function checkRepurchaseDeadline() external view returns (uint256 deadline);


    function checkPrice(uint256 tokenId) external view returns (address tokenAddr, uint256 tokenAmount);


    function checkReceipt(string memory receiptNum_) external view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 serviceFee,
        uint256 timestamp
    );


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Receiver.sol";
import "../interfaces/IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

    unchecked {
        // Will not overflow unless all 2**256 token ids are minted to the same owner.
        // Given that tokens are minted one by one, it is impossible in practice that
        // this ever happens. Might change if we allow batch minting.
        // The ERC fails to describe this case.
        _balances[to] += 1;
    }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

    unchecked {
        // Cannot overflow, as that would require more tokens to be burned/transferred
        // out than the owner initially received through minting and transferring in.
        _balances[owner] -= 1;
    }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

    unchecked {
        // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
        // `from`'s balance is the number of token held, which is at least one before the current
        // transfer.
        // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
        // all 2**256 token ids to be minted, which in practice is impossible.
        _balances[from] -= 1;
        _balances[to] += 1;
    }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called before consecutive token transfers.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     *
     * The default implementation include balances updates that extensions such as {ERC721Consecutive} cannot perform
     * directly.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after consecutive token transfers.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface CofferStructs {
    struct Receipt {
        string receiptNum;
        address operator;
        address NFTAddr;
        uint256 NFTId;
        address tokenAddr;
        uint256 tokenAmount;
        uint256 serviceFee;
        uint256 timestamp;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
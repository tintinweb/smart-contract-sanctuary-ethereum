/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
   
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract PhysicalLending is ERC721, Ownable {
    struct LendInfo {
        IERC20 loantoken;
        uint256 collateralValue;
        uint8 loanToValue;
        uint256 loanAmount;
        uint8 interestrate;
        string loanDuration;
        string paymentIntervals;
        uint256 dueAmount;
        address loanReceiverAddress;
        address repayAddress;
        uint8 totalNumberOfRepayment;
        string penalty;
        uint8 penaltyIntrest;
    }
   
    LendInfo Tokeninfo;

    struct dudates {
        uint8 dues;
        uint32 date;
    }

    dudates [] private dues;
    mapping(uint8 => uint32) private due;
    bool public tokenMint = false;
    bool public tokenLend = false;
    uint8 private _pendingRepayment;
    uint8 private _completedPayments=0;
    string private uri = "";
    uint private collateralValue;
    uint private day = 86400;
    uint private hour = 3600;
    constructor(string memory assetName, string memory symbol, string memory _uri, uint256 _collateralValue) ERC721(assetName, symbol) {
        uint8 tokenId = 1;
        collateralValue = _collateralValue;
        _safeMint(msg.sender, tokenId);
        _setBaseURI(_uri);
    }

    function _setBaseURI(string memory _uri) internal virtual {
        uri = _uri;
    }

    function documentURL() public virtual view returns(string memory){
        return uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function addContractDetails(
            IERC20 paytoken_,
            uint8 loanToValue_,
            uint256 loanAmount_,
            uint8 interestrate_,
            string memory loanDuration_,
            string memory paymentIntervals_,
            uint256 dueAmount_,
            address loanReceiverAddress_,
            uint32[] memory duerepaydate_,
            string memory penalty_,
            uint8 penaltyIntrest_
        ) public onlyOwner {
        require(tokenMint != true, "Token already Lended");
        Tokeninfo = LendInfo({
            loantoken: paytoken_,
            collateralValue: collateralValue,
            loanToValue: loanToValue_,
            loanAmount: loanAmount_,
            interestrate: interestrate_,
            loanDuration: loanDuration_,
            paymentIntervals: paymentIntervals_,
            dueAmount: dueAmount_,
            loanReceiverAddress: loanReceiverAddress_,
            repayAddress: msg.sender,
            totalNumberOfRepayment: uint8(duerepaydate_.length),
            penalty: penalty_,
            penaltyIntrest: penaltyIntrest_
            
        });
        uint32 duerepaydate;
        if(duerepaydate_.length > 0){
            for(uint8 i; i < duerepaydate_.length; i++){
                duerepaydate = duerepaydate_[i];
                setDeutime(i+1, duerepaydate);
                dudates memory setdeue = dudates(i, duerepaydate);
                dues.push(setdeue);
            }
        }
        tokenMint = true;
    }

    function setDeutime(uint8 i, uint32 duedate) private {
        due[i] = duedate;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getBalance(address _address) public virtual view returns(uint256){
        LendInfo storage tokens = Tokeninfo;
        IERC20 loantoken;
        loantoken = tokens.loantoken;
        return loantoken.balanceOf(_address);
    }

    function lend() public virtual returns(bool) {
        require(!tokenLend, "Token already lended");
        LendInfo storage tokens = Tokeninfo;
        IERC20 paytoken;
        paytoken = tokens.loantoken;
        require(paytoken.balanceOf(msg.sender) >= tokens.loanAmount, "Lend error: Insufficient balance");
        paytoken.approve(address(this), tokens.loanAmount);
        paytoken.transferFrom(msg.sender, tokens.loanReceiverAddress, tokens.loanAmount);
        _setPendingRepayment(tokens.totalNumberOfRepayment);
        tokenLend = true;
        tokenMint = true;
        return true;
    }

    function repay(address _to, uint _amount, uint8 numberofdue) public virtual returns(bool){
        LendInfo storage tokens = Tokeninfo;
        IERC20 paytoken;
        paytoken = tokens.loantoken;
        require(due[numberofdue] < block.timestamp, "Error : try to pay earlier");
        require((due[numberofdue] + day) > block.timestamp, "Error : You try to pay over the due day. kinldy try with re-pay with Penalty");
        require((_completedPayments + 1) == numberofdue, "Error : You try to pay incorrect due");
        require(_amount > 0, "Error : repay amount shoud be > 0");
        require(_amount >= tokens.dueAmount, "Error : you try to pay lesthan the deu amount");
        require(_pendingRepayment > 0, "Error: No pending payments");
        require(msg.sender != address(0), "Error: Repay from the zero address");
        require(_to != address(0), "Error: Repay to the zero address");
        require(tokens.repayAddress == _to, "Error: Repay to the zero address");
        require(paytoken.balanceOf(msg.sender) >= _amount, "You have insufficient token to supply that amount");
        paytoken.transferFrom(msg.sender, _to, _amount);
        _pendingRepayment= _pendingRepayment - 1;
        _completedPayments = _completedPayments + 1;
        return true;
    }

    function repayWithPenalty(address _to, uint _amount, uint8 numberofdue) public virtual returns(bool){
        LendInfo storage tokens = Tokeninfo;
        IERC20 paytoken;
        paytoken = tokens.loantoken;
        require((due[numberofdue]  + day) < block.timestamp, "Error : no panalty added try to pay with repay option");
        require((_completedPayments + 1) == numberofdue, "Error : You try to pay incorrect due");
        require(_amount > 0, "Error : repay amount shoud be > 0");
        require((_amount + _penaltyCalculation(numberofdue)) > tokens.dueAmount, "Error : you try to pay lesthan the due amount");
        require(_pendingRepayment > 0, "Error: No pending payments");
        require(msg.sender != address(0), "Error: Repay from the zero address");
        require(_to != address(0), "Error: Repay to the zero address");
        require(tokens.repayAddress == _to, "Error: Repay to the zero address");
        require(paytoken.balanceOf(msg.sender) >= _amount, "You have insufficient token to supply that amount");
        paytoken.transferFrom(msg.sender, _to, _amount);
        _pendingRepayment= _pendingRepayment - 1;
        _completedPayments = _completedPayments + 1;
        return true;
    }

    function _setPendingRepayment(uint8 _pendingRepay) internal virtual {
        _pendingRepayment = _pendingRepay;
    }

    function getNumberofRepaymentPending() public view virtual returns(uint8){
        return _pendingRepayment;
    }

    function getNumberofRepaymentCompleted() public view virtual returns(uint8){
        return _completedPayments;
    }

    function loanCoin() public view virtual returns(IERC20){
       LendInfo storage tokens = Tokeninfo;
       return tokens.loantoken;
    }

    function loanToValue() public view virtual returns(uint){
       LendInfo storage tokens = Tokeninfo;
       return tokens.loanToValue;
    }
    
    function loanAmount() public view virtual returns(uint){
       LendInfo storage tokens = Tokeninfo;
       return tokens.loanAmount;
    }

    function interestRate() public view virtual returns(uint){
       LendInfo storage tokens = Tokeninfo;
       return tokens.interestrate;
    }

    function loanDuration() public view virtual returns(string memory){
        LendInfo storage tokens = Tokeninfo;
        return tokens.loanDuration;
    }

    function paymentIntervals() public view virtual returns(string memory){
        LendInfo storage tokens = Tokeninfo;
        return tokens.paymentIntervals;
    }

    function dueAmount() public view virtual returns(uint){
        LendInfo storage tokens = Tokeninfo;
        return tokens.dueAmount;
    }

    function loanReceiverAddress() public view virtual returns(address){
        LendInfo storage tokens = Tokeninfo;
        return tokens.loanReceiverAddress;
    }

    function getDueDate(uint8 _numberofdue) public view virtual returns(uint){
        return due[_numberofdue];
    }

    function _penaltyCalculation(uint8 _numberofdue) internal virtual returns(uint){
        LendInfo storage tokens = Tokeninfo;
        uint penaltyTimes = _getPenalty(_numberofdue);
        uint panalty = dueAmount() * (tokens.penaltyIntrest / 100);
        return panalty * penaltyTimes;
    }

    function _getPenalty(uint8 _numberofdue) internal view virtual returns(uint){
        LendInfo storage tokens = Tokeninfo;
        uint dif;
        require(block.timestamp > (due[_numberofdue] + day) , "Error: not yet to complete due data");
        uint diffrence =  block.timestamp - (due[_numberofdue] + day);
        
        if(keccak256(abi.encodePacked(tokens.paymentIntervals)) == keccak256(abi.encodePacked("daily"))){
            dif = (diffrence * (10 ** 18)) / day;
        } else if(keccak256(abi.encodePacked(tokens.paymentIntervals)) == keccak256(abi.encodePacked("hourly"))){
            dif = (diffrence * (10 ** 18)) / hour;
        }
        bool condition = false;
        uint n1 = 0;
        uint n2 = n1+1;
        while(condition == false){
            if( dif >= n1 * (10**18) && dif < n2 * (10**18) ) {
               condition = true;
            } else {
                n1 = n2;
                n2 = n1+1;
            }
        }
        return n2;
    }
}
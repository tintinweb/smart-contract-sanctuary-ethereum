/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// File: contracts/openZeppelin/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/openZeppelin/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
pragma solidity ^0.8.1;

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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// File: contracts/openZeppelin/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: contracts/openZeppelin/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
pragma solidity ^0.8.0;


abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
// File: contracts/openZeppelin/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)
pragma solidity ^0.8.0;


interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
// File: contracts/openZeppelin/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)
pragma solidity ^0.8.0;


interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: contracts/openZeppelin/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)
pragma solidity ^0.8.0;


interface IERC1155MetadataURI is IERC1155 {

    function uri(uint256 id) external view returns (string memory);
}
// File: contracts/openZeppelin/ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







contract metaCasperz is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _uri;

    constructor(string memory uri_) {
        _setURI(uri_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: contracts/metaCasperzAttributes.sol


// metacasperzAttributes.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// ©2022 BlackBoxMint R&D
// [email protected]

pragma solidity 0.8.12;

contract metaCasperzAttributes {
    // Attributes

    uint256 private casperzAttributeType;
    uint256 private casperzAttributeCode;
    uint256 private casperzAttributeURL;
    uint256 private casperzAttributeWorn;

}
// File: contracts/metaCasperzVault.sol


// metacasperzVault.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// ©2022 BlackBoxMint R&D
// [email protected]

pragma solidity 0.8.12;

contract metaCasperzVault {
    uint256 internal casperzMintedTotal;
    uint256 internal casperzCurrentPrice;
    uint256 internal balance_vault;
    uint256 internal balance_caspers;
    uint256 internal balance_blackboxmint;
    address internal metacasperzVaultKeeper;
    address internal blackboxmintVaultKeeper;
    mapping(address => uint256) internal casperzCollectorsBalance;

    event caspEventVaultDeposit(string msg_1, address indexed sender, string msg_2, uint256 amount, string msg_3, uint256 totalBalance);
    event caspEventVaultKeeperTransfer(string msg_1, address from, string msg_2, address to);

    constructor() {
        metacasperzVaultKeeper = payable(msg.sender);
        blackboxmintVaultKeeper = payable(msg.sender);
        emit caspEventVaultKeeperTransfer("Vaultkeeper ", address(0), "transfered to ",  metacasperzVaultKeeper);
    }

    receive() external payable {
        emit caspEventVaultDeposit("Address ", msg.sender, "Deposits ", msg.value, "Balance now ", address(this).balance);
    }

    function _V_DEPOSIT () external payable {
        vaultShareHandling (msg.value);
        emit caspEventVaultDeposit("Address ", msg.sender, "Deposits ", msg.value, "Balance now ", address(this).balance);
    }

    function vaultShareHandling (uint256 _value) internal  {
        if (_value > 19){
            balance_blackboxmint += (_value * 5) / 100; 
        }
        balance_caspers += _value - balance_blackboxmint;
    }

    function _V_WITHDRAW_Casperz () external onlymetacasperzVaultKeeper {
        require(balance_caspers > 0, "The Vault has been cleared");
        (bool success, ) = metacasperzVaultKeeper.call{value: balance_caspers}("");
        require(success, "The vault is locked");
        balance_caspers -= balance_caspers;
    }

    function _V_WITHDRAW_Blackboxmint () external onlyblackboxmintVaultKeeper {
        require(balance_blackboxmint > 0, "The Vault has been cleared");
        (bool success, ) = blackboxmintVaultKeeper.call{value: balance_blackboxmint}("");
        require(success, "The vault is locked");
        balance_blackboxmint -= balance_blackboxmint;
    }

    function _V_SET__casperz(address _newCasperzKeeper) external onlymetacasperzVaultKeeper {
        metacasperzVaultKeeper = payable(_newCasperzKeeper);
        emit caspEventVaultKeeperTransfer("CasperzVaultkeeper ", address(0), "transfered to ",  metacasperzVaultKeeper);
    }
    function _V_SET_blackboxmint(address _newblackboxKeeper) external onlyblackboxmintVaultKeeper {
        blackboxmintVaultKeeper = payable(_newblackboxKeeper);
        emit caspEventVaultKeeperTransfer("BlackBoxVaultkeeper ", address(0), "transfered to ",  blackboxmintVaultKeeper);
    }

    function _V_KEEPER_CASPERZ() external view returns (address) {
        return metacasperzVaultKeeper;
    }

    function _V_KEEPER_BLACKBOX() external view returns (address) {
        return blackboxmintVaultKeeper;
    }

    function _V_CASPERZ_PRICE() external view returns (uint256) {
        return casperzCurrentPrice;
    }

    function _V_CASPERZ_MINTED() external view returns (uint256) {
        return casperzMintedTotal;
    }

    function _V_BALANCE_CASPERZ() external view returns (uint256) {
        return balance_caspers;
    }

    function _V_BALANCE_BLACKBOX() external view returns (uint256) {
        return balance_blackboxmint;
    }

    modifier onlymetacasperzVaultKeeper() {
        require(msg.sender == metacasperzVaultKeeper, "Caller is not metacasperzVaultKeeper");
        _;
    }

    modifier onlyblackboxmintVaultKeeper() {
        require(msg.sender == blackboxmintVaultKeeper, "Caller is not blackboxmintVaultKeeper");
        _;
    }
}
// File: contracts/metaCasperzSecurity.sol


// metaCasperzPortalLock.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// ©2022 BlackBoxMint R&D
// [email protected]

pragma solidity 0.8.12;

contract metaCasperzSecurity {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier portalLock() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier isLivingSoul() {
        require( contractAddressLength(msg.sender) == false , "The unliving may not pass");
        _;
    }
}

function contractAddressLength (address contractAddress) view returns (bool) {
    uint256 size;
        assembly {
        size := extcodesize(contractAddress)
    }
    return size > 0;
}

// File: contracts/metaCasperzAdmin.sol


// metaCasperzAdmin.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// ©2022 BlackBoxMint R&D
// [email protected]

pragma solidity 0.8.12;

contract metaCasperzAdmin {

    uint256 internal casperzMaxSupply = 3333;
    address internal casperzSuperAdmin;
    event casperzOwnerTransfer (address indexed oldAddress, address indexed newAddress);
        
    constructor() {
        casperzSuperAdmin = payable(msg.sender);
        emit casperzOwnerTransfer(address(0), casperzSuperAdmin);
    }

    function _ADMIN_SET_ADMIN (address newCasperzAdmin) external onlyCasperzSuperAdmin {
        casperzSuperAdmin = payable(newCasperzAdmin);
        emit casperzOwnerTransfer(casperzSuperAdmin, newCasperzAdmin);
    }

    function _ADMIN_SHOW_ADMIN() external view returns (address) {
        return casperzSuperAdmin;
    }

    function _ADMIN_SHOW_MAX() external view returns (uint256) {
        return casperzMaxSupply;
    }

    modifier onlyCasperzSuperAdmin() {
        require(msg.sender == casperzSuperAdmin, "Caller is not casperzSuperAdmin");
        _;
    }
}
// File: contracts/metaCasperzSpooks.sol


    // metaCasperzSpooks.sol ERC1155 v1.0
    // by Dr.Barns @metaCasperz
    // ©2022 BlackBoxMint R&D
    // [email protected]
    pragma solidity 0.8.12;



    
    contract metaCasperzSpooks is metaCasperzAdmin, metaCasperzSecurity, metaCasperzVault {

    uint256 internal casperzWhiteListID;
    mapping(address => uint256) internal casperzCollector;
    mapping(uint256 => uint256) internal casperzWhitelistEvents;
    mapping(address => mapping(uint256 => uint)) internal casperzWhitelisted;
    event caspEventWhiteListed(address indexed whitelisted, uint256 whitelistID);

    function _WL_ID () external view returns (uint256){ 
        return casperzWhiteListID;
    }

    function _WL_Capactity () external view returns (uint256){ 
        return casperzWhitelistEvents[casperzWhiteListID];
    }
    function _ADMIN_SET_whitelist (uint256 _whitelistCapactity) external onlyCasperzSuperAdmin portalLock {
        casperzWhiteListID ++;
        require(casperzWhitelistEvents[casperzWhiteListID] < 1, "This session has already begun");
        uint256 remainingCapacity = casperzMaxSupply - casperzMintedTotal;
        require(_whitelistCapactity <= remainingCapacity, "This session has already begun");
        casperzWhitelistEvents[casperzWhiteListID] = _whitelistCapactity;
    }

    function set_casperzCollector (address _address, uint256 _set) internal {
        casperzCollector[_address] = _set;
    }

    function check_casperzCollector(address _address) internal view returns (uint256) {
        return casperzCollector[_address];
    }

    function check_casperzWhiteliststatus(address _address) internal view returns (uint) {
        return casperzWhitelisted[_address][casperzWhiteListID];
    }

    function _WL_Status(address _address) external view returns (uint){
        return casperzWhitelisted[_address][casperzWhiteListID];
    }

    modifier onlyWhitelisted() {
        require(casperzWhiteListID > 0, "No Whitelisting events have been started" );
        require(check_casperzWhiteliststatus(msg.sender) != 0, "You are not whitelisted");
        require(check_casperzWhiteliststatus(msg.sender) == 1, "You have already collected your NFT");
        _;
    }

    modifier checkWhiteListPass() {
        require(casperzWhiteListID > 0, "No Whitelisting events have been started" );
        require(check_casperzWhiteliststatus(msg.sender) == 0, "You cannot sign up to the same whitelist twice");
        _;
    }
}

// File: contracts/metaCasperzMain.sol


// metaCasperzMain.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// ©2022 BlackBoxMint R&D
// [email protected]

pragma solidity 0.8.12;







contract metaCasperzMain is metaCasperz, metaCasperzAdmin, metaCasperzSecurity, metaCasperzVault, metaCasperzSpooks, metaCasperzAttributes {

    string internal constant casperzContractName = "Metacasperz";
    string internal constant casperzContractsymbol = "oOOo";
    
    event caspEventsetURI(address indexed setter, string newuri);
    event caspEventchangeMintedTotal(address indexed tester, uint256 newMintedTotal, uint256 newCurrentPrice);
    event caspEventMintAdmin(string msg_1, address indexed minter, string msg_2, uint256 amount, string msg_3, uint256 nextRelease, string msg_4, uint256 mintPrice);
    event caspEventMintWhitelisted(string msg_1, address indexed minter, string msg_2, uint256 nextRelease, string msg_3, uint256 mintPrice);
    event caspEventBurnHolder(address indexed burner, uint256 casperzType, uint256 casperzAmount);
    event caspEventWhiteListCapacity(address indexed whitelisted, uint capacity);

    constructor () metaCasperz("https://metacasperz.com/test/{id}.json"){    
    }

    function casperzSetURI(string memory newuri) external onlyCasperzSuperAdmin portalLock {
        _setURI(newuri);
        emit caspEventsetURI(msg.sender, newuri);
    }

    function casperzWhiteListMe() external payable portalLock checkWhiteListPass {
        require(casperzWhiteListID > 0, "No Whitelisting events have been started" );
        require(casperzWhitelistEvents[casperzWhiteListID] > 0, "All seats have been taken this whitelisting event" );
        casperzWhitelisted[msg.sender][casperzWhiteListID] = 1;
        casperzWhitelistEvents[casperzWhiteListID] -= 1; 
    }
     
    function casperzMintWhitelisted() external payable onlyWhitelisted portalLock isLivingSoul {    
        require(casperzMintedTotal <= casperzMaxSupply, "I am afraid casperz 3333 series has been completed");
        uint256 casperzTotalPrice = casperzCheckBatchPrice(1);
        require(casperzTotalPrice > 0, "Cannot cannot be 0");
        require(msg.value >= casperzTotalPrice, "You need to pay the minting price");
        vaultShareHandling(msg.value);
        casperzMintedTotal ++;
        _mint (msg.sender, casperzMintedTotal, 1, "");
        set_casperzCollector(msg.sender, casperzMintedTotal);
        casperzWhitelisted[msg.sender][casperzWhiteListID] = 2; 
        emit caspEventMintWhitelisted("Whitelisted Address: ", msg.sender, "Has just minted: ", casperzMintedTotal, "costing: ", casperzCurrentPrice);
    }

    function casperzCheckBatchPrice(uint256 _casperzAmount) internal returns (uint256 casperzMultiPrice){
        require(_casperzAmount > 0, "Amount cannot be 0");
        casperzCurrentPrice = returnCasperzCurrentPrice(casperzMintedTotal);
        casperzMultiPrice = casperzCurrentPrice * _casperzAmount;
        return casperzMultiPrice;
    }   
}

function returnCasperzCurrentPrice(uint256 _casperzMintedTotal) pure returns (uint256 _casperzCurrentPrice){
    _casperzCurrentPrice=1000000000000000000; // maximum by default
    if (_casperzMintedTotal < 11 ){
        _casperzCurrentPrice = 10000000000000000; // 0.01 ETH   
    }else if (_casperzMintedTotal > 10 && _casperzMintedTotal < 201){
        _casperzCurrentPrice = 20000000000000000; // 0.02 ETH       
    }else if (_casperzMintedTotal > 200 && _casperzMintedTotal < 501){
        _casperzCurrentPrice = 30000000000000000; // 0.03 ETH
    }else if (_casperzMintedTotal > 500 && _casperzMintedTotal < 1001){
        _casperzCurrentPrice = 80000000000000000; // 0.08 ETH
    }else if (_casperzMintedTotal > 1000 && _casperzMintedTotal < 2001){
        _casperzCurrentPrice = 110000000000000000; // 0.11 ETH
    }else if (_casperzMintedTotal > 2000 && _casperzMintedTotal < 3001){
        _casperzCurrentPrice = 140000000000000000; // 0.14 ETH
    }else{
        if (_casperzMintedTotal > 3000){
            _casperzCurrentPrice = 170000000000000000; // 0.17 ETH
        }
    }
    return _casperzCurrentPrice;
}
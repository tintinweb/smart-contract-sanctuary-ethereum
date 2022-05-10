// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VcgExchangeBase.sol";



/**
    Note: Simple contract to use as base for const vals
*/
contract CommonConstants {

    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}



// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, CommonConstants{
    using SafeMath for uint256;
    using Address for address;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

/////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256('supportsInterface(bytes4)'));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId)
    public virtual override
    view
    returns (bool) {
         if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
             _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
            return true;
         }

         return false;
    }

/////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external virtual override{

        _safeTransferFrom(_from, _to, _id, _value, _data);
    }
    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) internal virtual {

        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        // MUST emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        // Now that the balance is updated and the event was emitted,
        // call onERC1155Received if the destination is a contract.
        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }
    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external virtual override{
        _safeBatchTransferFrom(_from, _to, _ids, _values, _data);
    }
    function _safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) internal virtual {

        // MUST Throw on errors
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array length must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to]   = value.add(balances[id][_to]);
        }

        // Note: instead of the below batch versions of event and acceptance check you MAY have emitted a TransferSingle
        // event and a subsequent call to _doSafeTransferAcceptanceCheck in above loop for each balance change instead.
        // Or emitted a TransferSingle event for each in the loop and then the single _doSafeBatchTransferAcceptanceCheck below.
        // However it is implemented the balance changes and events MUST match when a check (i.e. calling an external contract) is done.

        // MUST emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        // Now that the balances are updated and the events are emitted,
        // call onERC1155BatchReceived if the destination is a contract.
        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }
    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external virtual override view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[_id][_owner];
    }

    function _balanceOf(address _owner, uint256 _id) internal virtual view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[_id][_owner];
    }
    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external virtual override view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external virtual override {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function _setApprovalForAll(address _operator, bool _approved) internal virtual  {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external virtual override view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

/////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.


        // Note: if the below reverts in the onERC1155Received function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
        require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155BatchReceived function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_BATCH_ACCEPTED test.
        require(ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == ERC1155_BATCH_ACCEPTED, "contract returned an unknown value from onERC1155BatchReceived");
    }
}


/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items.
*/
contract ERC1155Mintable is ERC1155,Ownable {
    using SafeMath for uint256;
    using Address for address;

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    // id => creators
    mapping (uint256 => address) public creators;

    mapping (uint256 => string) public uris;

    // A nonce to ensure we have a unique id each time we mint.
    uint256 public nonce;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

    function supportsInterface(bytes4 _interfaceId)
    public virtual override
    view
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    // Creates a new token type and assings _initialSupply to minter
    function create(uint256 _initialSupply, string calldata _uri) external returns(uint256 _id) {

        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);

        if (bytes(_uri).length > 0)
        {
            uris[_id] = _uri;
            emit URI(_uri, _id);
        }
    }

    // Batch mint tokens. Assign directly to _to[].
    function mint(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external creatorOnly(_id) {

        for (uint256 i = 0; i < _to.length; ++i) {

            address to = _to[i];
            uint256 quantity = _quantities[i];

            // Grant the items to the caller
            balances[_id][to] = quantity.add(balances[_id][to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, _id, quantity, '');
            }
        }
    }

    // Creates a new token type and assings _initialSupply to To Address
    function mintTo(address to, uint256 _initialSupply, string calldata _uri) external returns(uint256 _id) {

        return _mintTo(to,_initialSupply,_uri);
    }

    function _mintTo(address to, uint256 _initialSupply, string calldata _uri) internal returns(uint256 _id) {

        _id = ++nonce;
        creators[_id] = to;
        balances[_id][to] = _initialSupply;

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), to, _id, _initialSupply);

        if (bytes(_uri).length > 0)
        {
            uris[_id] = _uri;
            emit URI(_uri, _id);
        }
        return _id;
    }

    function setURI(string calldata _uri, uint256 _id) external creatorOnly(_id) {
        uris[_id] = _uri;
        emit URI(_uri, _id);
    }

    function tokenURI(uint256 _id) external view returns (string memory){
        return uris[_id];
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external virtual onlyOwner {
        /*
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        */
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external virtual onlyOwner {
        /*
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        */
        _burnBatch(account, ids, values);
    }
}





/**
 * @title VcgERC1155Token
 * 
 */
contract VcgERC1155Token is ERC1155Mintable {
    using SafeMath for uint256;
    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    // from => operator => id => allowance
    mapping(address => mapping(address => mapping(uint256 => uint256))) allowances;
    string constant private _name = "Vault by 500px's NFT";
    string constant private _symbol = "[email protected] by 500px";
    /*
    constructor() public {
    }
    */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    /**
        @dev MUST emit on any successful call to approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value)
    */
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);

    /**
        @notice Allow other accounts/contracts to spend tokens on behalf of msg.sender
        @dev MUST emit Approval event on success.
        To minimize the risk of the approve/transferFrom attack vector (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), this function will throw if the current approved allowance does not equal the expected _currentValue, unless _value is 0.
        @param _spender      Address to approve
        @param _id           ID of the Token
        @param _currentValue Expected current value of approved allowance.
        @param _value        Allowance amount
    */
    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external {
        address real_owner = msg.sender;
        uint256 balance = super._balanceOf(real_owner,_id);
        require(balance >= _value,"No enough balance to approve.");
        require(allowances[real_owner][_spender][_id] == _currentValue);
        allowances[real_owner][_spender][_id] = _value;
        
        super._setApprovalForAll(_spender,true);
        emit Approval(real_owner, _spender, _id, _currentValue, _value);
    }

    /**
        @notice Queries the spending limit approved for an account
        @param _id       ID of the Token
        @param _owner    The owner allowing the spending
        @param _spender  The address allowed to spend.
        @return          The _spender's allowed spending balance of the Token requested
     */
    function allowance(address _owner, address _spender, uint256 _id) external view returns (uint256){
        return allowances[_owner][_spender][_id];
    }

    // ERC1155
    /*
    function supportsInterface(bytes4 _interfaceId)
    external virtual override(ERC1155Mintable)
    view
    returns (bool) {
         ERC165(address(this)).supportsInterface(_interfaceId);
    }
    */
    function supportsInterface(bytes4 _interfaceId)
    public virtual override
    view
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    function checkTransfer(address _from, uint256 _id, uint256 _value) 
        internal {
        if (msg.sender != _from) {
            require(allowances[_from][msg.sender][_id] >= _value, "insufficient sender right.");
            allowances[_from][msg.sender][_id] = allowances[_from][msg.sender][_id].sub(_value);       
            //super._setApprovalForAll(_from,true);   
        }
    }

    function postTransfer(address _from)
        internal view {
        if (msg.sender != _from) {
            /*
            mapping(uint256 => uint256) storage ids_right = allowances[_from][msg.sender];
            uint256 len = ids_right.length;
            bool has_allowance = false;
            for(uint256 i=0;i<len;i++)
			{
                if(ids_right[i] > 0)
                {
                    has_allowance = true;
                }
            }
            if(!has_allowance){
                super.setApprovalForAll(_from,false);
            }
            */
        }
    }
    /**
        @notice Transfers value amount of an _id from the _from address to the _to addresses specified. Each parameter array should be the same length, with each index correlating.
        @dev MUST emit Transfer event on success.
        Caller must have sufficient allowance by _from for the _id/_value pair, or isApprovedForAll must be true.
        Throws if `_to` is the zero address.
        Throws if `_id` is not a valid token ID.
        Once allowance is checked the target contract's safeTransferFrom function is called.
        @param _from    source addresses
        @param _to      target addresses
        @param _id      ID of the Token
        @param _value   transfer amounts
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external override /*payable*/  {
        checkTransfer(_from,_id,_value);
        super._safeTransferFrom(_from, _to, _id, _value, _data);
        postTransfer(_from);
    }

    /**
        @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call)
        @dev MUST emit Transfer event per id on success.
        Caller must have a sufficient allowance by _from for each of the id/value pairs.
        Throws on any error rather than return a false flag to minimize user errors.
        Once allowances are checked the target contract's safeBatchTransferFrom function is called.
        @param _from    Source address
        @param _to      Target address
        @param _ids     Types of Tokens
        @param _values  Transfer amounts per token type
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override /*payable*/ {
        if (msg.sender != _from) {
            for (uint256 i = 0; i < _ids.length; ++i) {
                checkTransfer(_from,_ids[i],_values[i]);
            }
        }
        super._safeBatchTransferFrom(_from, _to, _ids, _values, _data);
        postTransfer(_from);
    }

  function isVcgNftToken(address tokenAddress) public view 
  returns(bool) {
      if( !Address.isContract(tokenAddress) ) 
      {
        return false;
      }
    
      bool result = false;
      string memory ex_name = VcgERC1155Token(tokenAddress).name();
      string memory ex_symbol = VcgERC1155Token(tokenAddress).symbol();   
              
      result = (keccak256(abi.encodePacked(ex_name)) == keccak256(abi.encodePacked(_name))) 
            && (keccak256(abi.encodePacked(ex_symbol)) == keccak256(abi.encodePacked(_symbol))) 
            && (supportsInterface(INTERFACE_SIGNATURE_URI) );     
      return result;
  }

  function isApprovedOrOwner(address owner, address spender, uint256 tokenId,uint256 value) external view returns (bool) {
    if(!_exists(tokenId) || (address(0) == spender))
    {
      return(false);      
    }
    uint256 balance = super._balanceOf(spender,tokenId);
    if(balance >= value)
    {
        return(true);
    }
    //return false;
    return (allowances[owner][spender][tokenId] >= value);
    //return (allowance(owner,spender,tokenId) >= value);
  }  

  function exists(uint256 tokenId) external view returns (bool) {
    
    return(_exists(tokenId));    
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return creators[tokenId] != address(0);
  }

  function isOwner(address owner, uint256 tokenId) external view returns (bool){
    if(!_exists(tokenId) || (address(0) == owner))
    {
      return(false);      
    }
    uint256 balance = super._balanceOf(owner,tokenId);
    return balance != 0 ;
  }
}



/**
 * @title VcgERC1155TokenWithRoyalty
 * 
 */
contract VcgERC1155TokenWithRoyalty is IERC2981,VcgERC1155Token{

    struct CreatorRight{
        address creator;
        uint32 royalty;
    }
    uint256 public _scaling_factor = 100000;//5 decimals
    event CreatorChanged(uint256 indexed _id, address indexed _creator);
    event DefultRoyaltyChanged(uint256 _royalty);

    // Mapping from Token ID to Creater whith royalty rate.
    mapping(uint256 => CreatorRight) private _royaltyInfos;

    modifier creatorRightOnly(uint256 _tokenId) {
        require(
            _royaltyInfos[_tokenId].creator == msg.sender, 
            "MintTLToken: ONLY_CREATOR_ALLOWED"
        );
        _;
    }


    /**
    * @dev Mints a token to an address with a tokenURI.
    * @param to address of the future owner of the token
    */
  function mintToWithRoyalty(address to, uint256 _initialSupply, string calldata _uri,uint32 value) public onlyOwner  returns (uint256){
    require(to != address(0), 'Royalties: Invalid recipient');
    require(value == 0 ||
        (value <= _scaling_factor && value>=_scaling_factor/100), 'Royalties: Abnormal');
    
    uint256 newTokenId = super._mintTo(to,_initialSupply,_uri);

    CreatorRight memory cr = CreatorRight(to,value);
    _royaltyInfos[newTokenId] = cr;
    //2021-10-08  , return New TokenID
    return newTokenId;
  }

  function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (
        address receiver,
        uint256 royaltyAmount
    ){
      CreatorRight memory cr = _royaltyInfos[_tokenId];
      if (cr.creator == address(0) || cr.royalty == 0){
          return (cr.creator,0);
      } 
      royaltyAmount = SafeMath.div(SafeMath.mul(_salePrice, cr.royalty),_scaling_factor);

      return (cr.creator,royaltyAmount);
  }

    function modifyRoyalty(uint256 _tokenId ,uint32 amount) external creatorRightOnly(_tokenId) {
        _royaltyInfos[_tokenId].royalty = amount;
    }

    function setCreator(uint256 _tokenId, address _to) public creatorRightOnly(_tokenId) {
        require(
            _to != address(0),
            "MintTLToken: INVALID_ADDRESS."
        );
        _royaltyInfos[_tokenId].creator = _to;
        emit CreatorChanged(_tokenId, _to);
    }

    function royaltyInfo(uint256 _tokenId) external view override returns (address receiver, uint256 amount) {
        receiver = _royaltyInfos[_tokenId].creator;
        amount = _royaltyInfos[_tokenId].royalty;
    }

    function onRoyaltiesReceived(address _royaltyRecipient, address _buyer, uint256 _tokenId, address _tokenPaid, uint256 _amount, bytes32 _metadata) external override returns (bytes4) {
        emit RoyaltiesReceived(_royaltyRecipient, _buyer, _tokenId, _tokenPaid, _amount, _metadata);    
        return bytes4(keccak256("onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)"));
    }
}
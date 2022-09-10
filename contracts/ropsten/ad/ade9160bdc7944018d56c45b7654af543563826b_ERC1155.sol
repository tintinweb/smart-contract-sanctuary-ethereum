/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: GPL-3.0-only

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
*/
pragma solidity ^0.8.3;


interface ERC1155TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external returns (bytes4);
}

contract ERC1155 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);


    // tokenID , address, balance  - tracks balances
    mapping(uint256 => mapping(address =>uint256)) internal _balances;

    // Owners address , Operator address , approval boolean - to check if an operator is approved to op the owners token
    mapping(address => mapping(address => bool)) private _operatorApprovals;



    function _checkOnERC1155Recieved(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == ERC1155TokenReceiver.onERC1155Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("receiver has not implemented ERC1155Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _checkOnBatchERC1155Recieved(
        address from,
        address to,
        uint256[] calldata _ids,
        bytes memory _data
    ) private returns (bool) {

        for(uint256 i = 0 ; i < _ids.length; i++){
        require(_checkOnERC1155Recieved(from,to,_ids[i],_data),"Reciever is not implemented");
        }
        return true;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }



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
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external{
        require(_from == msg.sender || isApprovedForAll(_from,msg.sender),"Sender is not owner or approved to transfer");
        require(_to != address(0), "Not a valid Recieving Address");
        _transfer(_from, _to, _id, _value);

        emit TransferSingle(msg.sender,_from,_to,_id,_value);
        //check if recieved
        require(_checkOnERC1155Recieved(_from,_to,_id,_data),"Reciever is not implemented");
    }

    function _transfer(address from, address to, uint256 id, uint256 amount) private {
        uint256 fromBlance = _balances[id][from]; // get the amount of NFTS this address is holding
        require(fromBlance >= amount ,"Insufficient Amount");
        //update balances accordingly
        _balances[id][from] = fromBlance - amount;
        _balances[id][to] += amount;
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
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external{
        require(_from == msg.sender || (isApprovedForAll(_from,msg.sender)),
        "Sender is not owner or approved to transfer"
        );
        require(_to != address(0), "Not a valid Recieving Address");
        require(_ids.length == _values.length, "Ids and ammounts dont correspond in length");

        for(uint256 i = 0 ; i < _ids.length; i++){
            
            uint256 id = _ids[i];
            uint256 amount = _values[i];
            _transfer(_from,_to,id,amount);

        }

        emit TransferBatch(msg.sender,_from,_to,_ids,_values);
        //check if recieved
        require(_checkOnBatchERC1155Recieved(_from,_to,_ids,_data),"Reciever not implemented");
    }
    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
    */
    
    function balanceOf(address _owner, uint256 _id) external view returns (uint256){
        require(_owner != address(0), "Address is not valid");
        return _balances[_id][_owner];
    }
    /**
        @notice Get the balance of multiple account/token pairs
        @param accounts The addresses of the token holders
        @param ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address [] memory accounts, uint256 [] memory ids) public view returns (uint256[] memory){
        require(accounts.length == ids.length, "Lengths of accounts and ids are not the same");
        //creating an array with dynamic length to fetch balances - must match the length of accounts
        uint256 arrLength= accounts.length;
        uint256 [] memory batchBlances = new uint256[](arrLength);
        for(uint256 i = 0 ; i < arrLength ; i++){

            batchBlances[i] = _balances[ids[i]][accounts[i]];
        }
        return batchBlances;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external{
        require(_operator != address(0),"Operator Address is not valid");
        require(msg.sender != _operator,"You are already the operatoe for this account");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator,_approved);
    }
    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        require(_owner != address(0) || _operator != address(0) , "Operator/Owner Address is not valid");
        return _operatorApprovals[_owner][_operator];
    }
}
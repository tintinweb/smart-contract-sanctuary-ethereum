// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract WalletRegistry {

    /**
      * @dev owner to delegate candidates. The relations available here don't confirm
      * that the pair is valid. Wallets pair validity must always be checked against
      * the "isPairValid()" function
    */
    mapping(address => address) private ownerToDelegate;

    /**
      * @dev delegate to owner candidates. The relations available here don't confirm
      * that the pair is valid. Wallets pair validity must always be checked against
      * the "isPairValid()" function
    */
    mapping(address => address) private delegateToOwner;

    /** 
      * @dev changing delegate address for the owner address.
      * @param _delegate delegate address to be registered for the current address.
     */
    function changeDelegate(address _delegate) external {

        require(
            _delegate != msg.sender,
            "Can't delegate to self."
        );
        require(
            delegateToOwner[_delegate] == address(0),
            "Delegate is already in use"
        );

        // If another delegate was set to this owner address, remove old delegate to 
        // owner relation
        if (ownerToDelegate[msg.sender] != address(0)) {
            address oldDelegate = ownerToDelegate[msg.sender];
            delegateToOwner[oldDelegate] = address(0);
        }
        
        // Set new owner-to-delegate relation.
        ownerToDelegate[msg.sender] = _delegate;
    }

    /** 
      * @dev confirm owner address from the delegate address.
      * @param _owner owner address to be registered for the current delegate address.
     */
    function confirmOwner(address _owner) external {

        require(
            ownerToDelegate[_owner] == msg.sender,
            "You should set delegate first."
        );

        delegateToOwner[msg.sender] = _owner;
    }

    /** 
      * @dev deletes bindings between msg.sender and his delegate address
      * @param _delegate delegate address of the msg.sender
     */
    function deleteDelegate(address _delegate) external {
        require(
            isPairValid(msg.sender, _delegate),
            "Pair is invalid"
        );

        delegateToOwner[_delegate] = address(0);
        ownerToDelegate[msg.sender] = address(0);
    }

    /** 
      * @dev retrieving delegate by owner candidate. The relation returned here doesn't confirm
      * that the pair is valid. Wallets pair validity must always be checked against
      * the "isPairValid()" function
      * @param _owner owner address to retrieve delegate address from.
      * @return delegate_ delegate address for the specified owner address. Doesn't confirm
      * that this pair is valid
     */
    function getDelegate(address _owner) external view returns(address delegate_) {
        return ownerToDelegate[_owner];
    }

    /** 
      * @dev retrieving owner by delegate candidate. The relation returned here doesn't confirm
      * that the pair is valid. Wallets pair validity must always be checked against
      * the "isPairValid()" function
      * @param _delegate delegate address to retrieve owner address from.
      * @return owner_ owner address for the specified delegate address. Doesn't confirm
      * that this pair is valid
     */
    function getOwner(address _delegate) external view returns(address owner_) {
        return delegateToOwner[_delegate];
    }

    /** 
      * @dev check if delegate pair exists for the owner wallet.
      * @param _owner owner address to retrieve delegate address from.
      * @param _delegate delegate address to retrieve owner address from.
      * @return isValid_ is true if owner to delegate and delegate to owner pair is 
      * valid, false otherwise
     */
    function isPairValid(address _owner, address _delegate) public view returns(bool isValid_) {

        require(
            _owner != address(0),
            "Owner address can't be address(0)."
        );

        require(
            _delegate != address(0),
            "Delegate address can't be address(0)."
        );

        bool isDelegateValid = (ownerToDelegate[_owner] == _delegate);
        bool isOwnerValid = (delegateToOwner[_delegate] == _owner);

        return (isDelegateValid && isOwnerValid);
    }
}
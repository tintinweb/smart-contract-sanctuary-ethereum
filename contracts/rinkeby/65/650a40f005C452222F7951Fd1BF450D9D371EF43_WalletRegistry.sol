// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract WalletRegistry {

    mapping(address => address) ownerToDelegate;
    mapping(address => address) delegateToOwner;

    /** 
      * @dev changing delegate address for the owner address.
      * @param _toAddress delegate address to be registered for the current address.
     */
    function changeDelegate(address _toAddress) external {

        require(
            _toAddress != msg.sender,
            "Can't delegate to self."
        );
        require(
            delegateToOwner[_toAddress] == address(0),
            "Delegate is already in use"
        );

        if (ownerToDelegate[msg.sender] != address(0)) {
            address oldDelegate = ownerToDelegate[msg.sender];
            delegateToOwner[oldDelegate] = address(0);
        }
        // Set new owner-to-delegate relation.
        ownerToDelegate[msg.sender] = _toAddress;
    }

    /** 
      * @dev confirm delegate address for the owner address.
      * @param _fromAddress owner address to be registered for the current address.
     */
    function confirmDelegate(address _fromAddress) external {

        require(
            ownerToDelegate[_fromAddress] == msg.sender,
            "You should set delegate first."
        );

        delegateToOwner[msg.sender] = _fromAddress;
    }

    /** 
      * @dev delete delegate address.
     */
    function deleteDelegate() external {

        require(
            delegateToOwner[msg.sender] != address(0),
            "Delegate is not registered."
        );

        // Delete old delegate-to-owner relation.
        delegateToOwner[msg.sender] = address(0);
    }

    /** 
      * @dev retrieving delegate address from the owner address.
      * @param _fromAddress owner address to retrieve delegate address from.
      * @return delegate_ delegate address for the specified owner address.
     */
    function getDelegate(address _fromAddress) external view returns(address delegate_) {
        return ownerToDelegate[_fromAddress];
    }

    /** 
      * @dev retrieving owner address from the delegate address.
      * @param _fromAddress delegate address to retrieve owner address from.
      * @return owner_ owner address for the specified delegate address.
     */
    function getOwner(address _fromAddress) external view returns(address owner_) {
        return delegateToOwner[_fromAddress];
    }

    /** 
      * @dev check if delegate pair exists for the owner wallet.
      * @param _fromAddress owner address to retrieve delegate address from.
      * @param _toAddress delegate address to retrieve owner address from.
      * @return isValid_ is true if delegate exists; false if not
     */
    function isPairValid(address _fromAddress, address _toAddress) external view returns(bool isValid_) {

        require(
            _fromAddress != address(0),
            "Owner address can't be address(0)."
        );

        require(
            _toAddress != address(0),
            "Owner address can't be address(0)."
        );

        bool isDelegateValid = (ownerToDelegate[_fromAddress] == _toAddress);
        bool isOwnerValid = (delegateToOwner[_toAddress] == _fromAddress);

        return (isDelegateValid && isOwnerValid);
    }
}
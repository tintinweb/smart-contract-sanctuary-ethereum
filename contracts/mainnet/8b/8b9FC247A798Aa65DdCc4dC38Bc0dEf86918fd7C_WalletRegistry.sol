// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IWalletRegistry {
    /**
     * @notice emitted when the first step of pairing wallets happens and the owner confirms
     * connection to the delegate. The delegate doesn't confirm the connection at this point.
     * @param _potentialOwner owner who confirmed the connection
     * @param _potentialDelegate paired wallet, no confirmation from it at this point
     */
    event DelegateChanged(
        address indexed _potentialOwner,
        address indexed _potentialDelegate
    );

    /**
     * @notice emitted when the second first step of pairing wallets happens and the delegate confirms
     * connection to the owner. Valid pair of wallets is created.
     * @param _owner owner who confirmed the connection
     * @param _delegate paired wallet who confirmed the connection
     */
    event OwnerConfirmed(address indexed _owner, address indexed _delegate);

    /**
     * @notice emitted when the owner wallet deletes the connection to the delegate wallet
     * @param _owner owner who deleted the connection
     * @param _delegate connection with this wallet is deleted
     */
    event DelegateDeleted(address indexed _owner, address indexed _delegate);

    /**
     * @notice changing delegate address for the owner address.
     * @param _delegate delegate address to be registered for the current address.
     */
    function changeDelegate(address _delegate) external;

    /**
     * @notice confirm owner address from the delegate address.
     * @param _owner owner address to be registered for the current delegate address.
     */
    function confirmOwner(address _owner) external;

    /**
     * @notice deletes bindings between msg.sender and his delegate address
     * @param _delegate delegate address of the msg.sender
     */
    function deleteDelegate(address _delegate) external;

    /**
     * @notice retrieving delegate by owner candidate. The relation returned here doesn't confirm
     * that the pair is valid. Wallets pair validity must always be checked against
     * the "isPairValid()" function
     * @param _owner owner address to retrieve delegate address from.
     * @return delegate_ delegate address for the specified owner address. Doesn't confirm
     * that this pair is valid
     */
    function getDelegate(address _owner)
        external
        view
        returns (address delegate_);

    /**
     * @notice retrieving owner by delegate candidate. The relation returned here doesn't confirm
     * that the pair is valid. Wallets pair validity must always be checked against
     * the "isPairValid()" function
     * @param _delegate delegate address to retrieve owner address from.
     * @return owner_ owner address for the specified delegate address. Doesn't confirm
     * that this pair is valid
     */
    function getOwner(address _delegate) external view returns (address owner_);

    /**
     * @notice check if delegate pair exists for the owner wallet.
     * @param _owner owner address to retrieve delegate address from.
     * @param _delegate delegate address to retrieve owner address from.
     * @return isValid_ is true if owner to delegate and delegate to owner pair is
     * valid, false otherwise
     */
    function isPairValid(address _owner, address _delegate)
        external
        view
        returns (bool isValid_);
}

contract WalletRegistry is IWalletRegistry {
    /**
     * @notice owner to delegate candidates. The relations available here don't confirm
     * that the pair is valid. Wallets pair validity must always be checked against
     * the "isPairValid()" function
     */
    mapping(address => address) private ownerToDelegate;

    /**
     * @notice delegate to owner candidates. The relations available here don't confirm
     * that the pair is valid. Wallets pair validity must always be checked against
     * the "isPairValid()" function
     */
    mapping(address => address) private delegateToOwner;

    function changeDelegate(address _delegate) external override {
        require(_delegate != msg.sender, "Can't delegate to self.");
        require(
            delegateToOwner[_delegate] == address(0),
            "Delegate is already in use"
        );

        // If another delegate was set to this owner address, remove old delegate to
        // owner relation
        if (
            ownerToDelegate[msg.sender] != address(0) &&
            _isPairValid(msg.sender, ownerToDelegate[msg.sender])
        ) {
            address oldDelegate = ownerToDelegate[msg.sender];
            delegateToOwner[oldDelegate] = address(0);
        }

        // Set new owner-to-delegate relation.
        ownerToDelegate[msg.sender] = _delegate;

        emit DelegateChanged(msg.sender, _delegate);
    }

    function confirmOwner(address _owner) external override {
        require(
            ownerToDelegate[_owner] == msg.sender,
            "You should set delegate first."
        );

        delegateToOwner[msg.sender] = _owner;

        emit OwnerConfirmed(_owner, msg.sender);
    }

    function deleteDelegate(address _delegate) external override {
        require(_isPairValid(msg.sender, _delegate), "Pair is invalid");

        delegateToOwner[_delegate] = address(0);
        ownerToDelegate[msg.sender] = address(0);

        emit DelegateDeleted(msg.sender, _delegate);
    }

    function getDelegate(address _owner)
        external
        view
        override
        returns (address delegate_)
    {
        return ownerToDelegate[_owner];
    }

    function getOwner(address _delegate)
        external
        view
        override
        returns (address owner_)
    {
        return delegateToOwner[_delegate];
    }

    function isPairValid(address _owner, address _delegate)
        external
        view
        override
        returns (bool isValid_)
    {
        isValid_ = _isPairValid(_owner, _delegate);
    }

    /**
     * @notice check if delegate pair exists for the owner wallet.
     * @param _owner owner address to retrieve delegate address from.
     * @param _delegate delegate address to retrieve owner address from.
     * @return isValid_ is true if owner to delegate and delegate to owner pair is
     * valid, false otherwise
     */
    function _isPairValid(address _owner, address _delegate)
        internal
        view
        returns (bool)
    {
        require(_owner != address(0), "Owner address can't be address(0).");

        require(
            _delegate != address(0),
            "Delegate address can't be address(0)."
        );

        bool isDelegateValid = (ownerToDelegate[_owner] == _delegate);
        bool isOwnerValid = (delegateToOwner[_delegate] == _owner);

        return (isDelegateValid && isOwnerValid);
    }
}
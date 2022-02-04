/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Simple multi-sig Wallet.
 */
contract Wallet {
    bool isInit;

    uint256 public threshold;
    uint256 private transactionIndex;
    uint256 private updatethresholdIndex;
    uint256 private removeOwnerIndex;
    uint256 private addOwnerIndex;

    address[] public owners;

    mapping(address => bool) isOwner;
    mapping(address => mapping(uint256 => bool)) transactionSigners;
    mapping(address => mapping(uint256 => bool)) updatethresholdSigners;
    mapping(address => mapping(uint256 => bool)) removeOwnerSigners;
    mapping(address => mapping(uint256 => bool)) addOwnerSigners;

    event NewTransaction(address to, uint256 value, address sender);
    event NewDeposit(address _sender, uint256 _value);
    event NewThreshold(
        uint256 oldThreshold,
        uint256 newthreshold,
        address sender
    );
    event OwnerRemoved(address removed, address sender);
    event OwnerAdded(address newOwner, address sender);

    struct Transaction {
        address to;
        uint256 value;
        uint256 index;
        uint256 signatures;
        bool approved;
    }
    struct UpdateThreshold {
        uint256 threshold;
        uint256 index;
        uint256 signatures;
        bool approved;
    }
    struct RemoveOwner {
        address remove;
        uint256 index;
        uint256 signatures;
        bool approved;
    }
    struct AddOwner {
        address add;
        uint256 index;
        uint256 signatures;
        bool approved;
    }

    Transaction[] transactions;
    UpdateThreshold[] updatethreshold;
    RemoveOwner[] removeOwner;
    AddOwner[] addOwner;

    receive() external payable {
        emit NewDeposit(msg.sender, msg.value);
    }

    // checks if the caller is an owner.
    modifier onlyOwners() {
        require(isOwner[msg.sender], "Not owner");

        _;
    }

    function setAddresses(address[] memory _owners, uint256 _threshold) public {
        require(!isInit, "wallet in use");
        require(_owners.length > 0, "There needs to be more than 0 owners");
        require(_threshold <= _owners.length, "threshold exceeds owners");
        require(_threshold > 0, "threshold needs to be more than 0");
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(!isOwner[owner], "Address already an owner");
            require(owner != address(this), "This address can't be owner");
            require(owner != address(0), "Address 0 can't be owner");
            owners.push(owner);
            isOwner[owner] = true;
        }
        threshold = _threshold;
        isInit = true;
    }

    /**
     * @notice creates a transaction request and adds one signature.
     * @param _to - receiver of the transaction.
     * @param _value - amount in WEI.
     */
    function transactionRequest(address _to, uint256 _value)
        external
        onlyOwners
    {
        require(address(this).balance >= _value, "Not enough funds");
        require(_to != address(0), "address zero not supported");
        require(_value > 0, "Value cannot be 0");
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                index: transactionIndex,
                signatures: 0,
                approved: false
            })
        );
        transactionIndex += 1;
    }

    /**
     * @notice approves a transaction after reaching the threshold
     * @param _index index of the transaction.
     */
    function transactionApproval(uint256 _index) external onlyOwners {
        require(transactions[_index].value >= 0, "Transaction does not exists");
        require(
            transactionSigners[msg.sender][_index] == false,
            "You already signed this transaction"
        );
        Transaction storage t = transactions[_index];
        require(!t.approved, "Transaction already approved");
        t.signatures += 1;
        transactionSigners[msg.sender][_index] = true;
        if (t.signatures >= threshold) {
            (bool sent, ) = t.to.call{value: t.value}("");
            require(sent, "Transaction failed");
            t.approved = true;
            emit NewTransaction(t.to, t.value, msg.sender);
        }
    }

    /**
     * @notice creates a request to update the threshold and adds a signature.
     * @param _newThreshold the new threshold.
     */
    function updatethresholdRequest(uint256 _newThreshold) external onlyOwners {
        require(
            _newThreshold <= totalOwners(),
            "threshold exceeds total owners"
        );
        require(_newThreshold > 0, "You need at least threshold of 1");
        updatethreshold.push(
            UpdateThreshold({
                threshold: _newThreshold,
                index: updatethresholdIndex,
                signatures: 0,
                approved: false
            })
        );
        updatethresholdIndex += 1;
    }

    /**
     * @notice updates the threshold after reaching the threshold.
     * @param _index transaction index.
     */
    function updatethresholdApproval(uint256 _index) external onlyOwners {
        require(
            updatethreshold[_index].threshold > 0,
            "Transaction does not exists"
        );
        require(
            updatethresholdSigners[msg.sender][_index] == false,
            "Owner already signed this transaction"
        );
        UpdateThreshold storage uq = updatethreshold[_index];
        require(!uq.approved, "Transaction already approved");
        uq.signatures += 1;
        updatethresholdSigners[msg.sender][_index] = true;
        if (uq.signatures >= threshold) {
            emit NewThreshold(threshold, uq.threshold, msg.sender);
            threshold = uq.threshold;
            uq.approved = true;
        }
    }

    /**
     * @notice request to remove an owner.
     * @param _remove the owner to remove.
     */
    function removeOwnerRequest(address _remove) external onlyOwners {
        require(isOwner[_remove], "Address is not an owner");
        require((totalOwners() - 1) > 0, "There needs to be at least 1 owner");
        require(
            (totalOwners() - 1) >= threshold,
            "There needs to be more owners than threshold"
        );
        removeOwner.push(
            RemoveOwner({
                remove: _remove,
                index: removeOwnerIndex,
                signatures: 0,
                approved: false
            })
        );
        removeOwnerIndex += 1;
    }

    /**
     * @notice removes an owner after reaching the threshold.
     * @param _index the transaction index.
     */
    function removeOwnerApproval(uint256 _index) external onlyOwners {
        require(
            removeOwnerSigners[msg.sender][_index] == false,
            "You already signed this transaction"
        );
        RemoveOwner storage rmvOwner = removeOwner[_index];
        require(!rmvOwner.approved, "Transaction already approved");
        address toRemove = rmvOwner.remove;
        rmvOwner.signatures += 1;
        removeOwnerSigners[msg.sender][_index] = true;
        if (rmvOwner.signatures >= threshold) {
            uint256 index;
            for (uint256 i = 0; i < owners.length; i++) {
                if (owners[i] == toRemove) {
                    index = i;
                    isOwner[owners[i]] = false;
                }
            }
            delete owners[index];
            emit OwnerRemoved(toRemove, msg.sender);
            rmvOwner.approved = true;
        }
    }

    /**
     * @notice Request to add an owner and adds a signature.
     * @param _newOwner new owner to add.
     */
    function addOwnerRequest(address _newOwner) external onlyOwners {
        require(!isOwner[_newOwner], "address already an owner");
        require(
            _newOwner != address(this) && _newOwner != address(0),
            "Incorrect address"
        );
        addOwner.push(
            AddOwner({
                add: _newOwner,
                index: addOwnerIndex,
                signatures: 0,
                approved: false
            })
        );
        addOwnerIndex += 1;
    }

    /**
     * @notice adds an owner after reaching the threshold.
     * @param _index the transaction index.
     */
    function addOwnerApproval(uint256 _index) external onlyOwners {
        require(
            addOwnerSigners[msg.sender][_index] == false,
            "You already signed this transaction"
        );
        AddOwner storage _addOwner = addOwner[_index];
        address toAdd = _addOwner.add;
        require(!_addOwner.approved, "Transaction already approved");
        _addOwner.signatures += 1;
        addOwnerSigners[msg.sender][_index] = true;
        if (_addOwner.signatures >= threshold) {
            owners.push(toAdd);
            isOwner[toAdd] = true;
            emit OwnerAdded(toAdd, msg.sender);
            _addOwner.approved = true;
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    ///              ------------>    VIEW HELPER FUNCTIONS.   <--------------

    /**
     * @return returns an array of the indexes of the pending transactions.
     */
    function pendingTransactionsIndex()
        private
        view
        returns (uint256[] memory)
    {
        uint256 counter;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].approved == false) {
                counter += 1;
            }
        }
        uint256[] memory result = new uint256[](counter);
        uint256 index;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].approved == false) {
                result[index] = i;
                index += 1;
            }
        }
        return result;
    }

    /**
     * @return an array of pending transactions in struct format.
     */
    function pendingTransactionsData()
        external
        view
        onlyOwners
        returns (Transaction[] memory)
    {
        uint256[] memory pendingTr = pendingTransactionsIndex();
        Transaction[] memory t = new Transaction[](pendingTr.length);
        for (uint256 i = 0; i < pendingTr.length; i++) {
            t[i] = transactions[pendingTr[i]];
        }
        return t;
    }

    /**
     * @return an array of the indexes of the pending update threshold transactions.
     */
    function pendingUpdatethresholdIndex()
        private
        view
        returns (uint256[] memory)
    {
        uint256 counter;
        for (uint256 i = 0; i < updatethreshold.length; i++) {
            if (updatethreshold[i].approved == false) {
                counter += 1;
            }
        }
        uint256[] memory result = new uint256[](counter);
        uint256 index;
        for (uint256 i = 0; i < updatethreshold.length; i++) {
            if (updatethreshold[i].approved == false) {
                result[index] = i;
                index += 1;
            }
        }
        return result;
    }

    /**
     * @return an array of the indexes of the pending update threshold transactions.
     */
    function pendingUpdatethresholdData()
        external
        view
        onlyOwners
        returns (UpdateThreshold[] memory)
    {
        uint256[] memory pendingUQ = pendingUpdatethresholdIndex();
        UpdateThreshold[] memory uq = new UpdateThreshold[](pendingUQ.length);
        for (uint256 i = 0; i < pendingUQ.length; i++) {
            uq[i] = updatethreshold[pendingUQ[i]];
        }
        return uq;
    }

    /**
     * @return an array of the indexes of the pending remove owner transactions.
     */
    function pendingRemoveOwnerIndex() private view returns (uint256[] memory) {
        uint256 counter;
        for (uint256 i = 0; i < removeOwner.length; i++) {
            if (removeOwner[i].approved == false) {
                counter += 1;
            }
        }
        uint256[] memory result = new uint256[](counter);
        uint256 index;
        for (uint256 i = 0; i < removeOwner.length; i++) {
            if (removeOwner[i].approved == false) {
                result[index] = i;
                index += 1;
            }
        }
        return result;
    }

    ///@return an array of pending remove owner transactions in struct format.
    function pendingRemoveOwnerData()
        external
        view
        onlyOwners
        returns (RemoveOwner[] memory)
    {
        uint256[] memory pendingRO = pendingRemoveOwnerIndex();
        RemoveOwner[] memory ro = new RemoveOwner[](pendingRO.length);
        for (uint256 i = 0; i < pendingRO.length; i++) {
            ro[i] = removeOwner[pendingRO[i]];
        }
        return ro;
    }

    ///@return returns an array of the indexes of the pending add owner transactions.
    function pendingAddOwnerIndex() private view returns (uint256[] memory) {
        uint256 counter;
        for (uint256 i = 0; i < addOwner.length; i++) {
            if (addOwner[i].approved == false) {
                counter += 1;
            }
        }
        uint256[] memory result = new uint256[](counter);
        uint256 index;
        for (uint256 i = 0; i < addOwner.length; i++) {
            if (addOwner[i].approved == false) {
                result[index] = i;
                index += 1;
            }
        }
        return result;
    }

    ///@return an array of pending add owner transactions in struct format.
    function pendingAddOwnerData()
        external
        view
        onlyOwners
        returns (AddOwner[] memory)
    {
        uint256[] memory pendingAO = pendingAddOwnerIndex();
        AddOwner[] memory ao = new AddOwner[](pendingAO.length);
        for (uint256 i = 0; i < pendingAO.length; i++) {
            ao[i] = addOwner[pendingAO[i]];
        }
        return ao;
    }

    ///@return uint of total active owners.
    function totalOwners() public view returns (uint256) {
        uint256 result;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] != address(0)) {
                result += 1;
            }
        }
        return result;
    }

    /// @return an array of the addresses of the owners.
    function getOwnersAddress() external view returns (address[] memory) {
        require(owners.length > 0, "0 owners not valid, ERROR!");
        uint256 counter;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] != address(0)) {
                counter += 1;
            }
        }
        address[] memory result = new address[](counter);
        uint256 index;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] != address(0)) {
                result[index] = owners[i];
                index += 1;
            }
        }
        return result;
    }
}
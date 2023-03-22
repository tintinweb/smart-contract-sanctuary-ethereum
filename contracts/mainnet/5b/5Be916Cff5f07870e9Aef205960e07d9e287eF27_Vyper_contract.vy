# @version ^0.3.6


# Interfaces

interface ILoansPeripheral:
    def lendingPoolPeripheralContract() -> address: view

interface ILendingPoolPeripheral:
    def erc20TokenContract() -> address: view


# Structs

struct Collateral:
    contractAddress: address
    tokenId: uint256
    amount: uint256

struct Loan:
    id: uint256
    amount: uint256
    interest: uint256 # parts per 10000, e.g. 2.5% is represented by 250 parts per 10000
    maturity: uint256
    startTime: uint256
    collaterals: DynArray[Collateral, 100]
    paidPrincipal: uint256
    paidInterestAmount: uint256
    started: bool
    invalidated: bool
    paid: bool
    defaulted: bool
    canceled: bool

struct TopStats:
    highestSingleCollateralLoan: Loan
    highestCollateralBundleLoan: Loan
    highestRepayment: Loan
    highestDefaultedLoan: Loan


# Events

event OwnerProposed:
    ownerIndexed: indexed(address)
    proposedOwnerIndexed: indexed(address)
    owner: address
    proposedOwner: address
    erc20TokenContract: address

event OwnershipTransferred:
    ownerIndexed: indexed(address)
    proposedOwnerIndexed: indexed(address)
    owner: address
    proposedOwner: address
    erc20TokenContract: address

event LoansPeripheralAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address


# Global variables

owner: public(address)
proposedOwner: public(address)

loansPeripheral: public(address)

loans: HashMap[address, DynArray[Loan, 2**16]]
borrowedAmount: public(HashMap[address, uint256])
ongoingLoans: public(HashMap[address, uint256])

# key: bytes32 == _abi_encoded(token_address, token_id) -> map(borrower_address, loan_id)
collateralsInLoans: public(HashMap[bytes32, HashMap[address, uint256]]) # given a collateral and a borrower, what is the loan id
collateralsInLoansUsed: public(HashMap[bytes32, HashMap[address, HashMap[uint256, bool]]]) # given a collateral, a borrower and a loan id, is the collateral still used in that loan id
collateralKeys: DynArray[bytes32, 2**20] # array of collaterals expressed by their keys
collateralsUsed: public(HashMap[bytes32, bool]) # given a collateral, is it being used in a loan
collateralsData: public(HashMap[bytes32, Collateral]) # given a collateral key, what is its data
collateralsIdsByAddress: HashMap[address, DynArray[uint256, 2**20]] # given a collateral address, what are the token ids that were already in a loan

collectionsBorrowedAmount: public(HashMap[address, uint256])

# Stats
topStats: TopStats


##### INTERNAL METHODS #####

@view
@internal
def _isLoanCreated(_borrower: address, _loanId: uint256) -> bool:
    return _loanId < len(self.loans[_borrower])


@view
@internal
def _isLoanStarted(_borrower: address, _loanId: uint256) -> bool:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].started
    return False


@view
@internal
def _isLoanInvalidated(_borrower: address, _loanId: uint256) -> bool:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].invalidated
    return False


@pure
@internal
def _computeCollateralKey(_collateralAddress: address, _collateralId: uint256) -> bytes32:
  return keccak256(_abi_encode(_collateralAddress, convert(_collateralId, bytes32)))


@internal
def _addCollateralToLoan(_borrower: address, _collateral: Collateral, _loanId: uint256):
  key: bytes32 = self._computeCollateralKey(_collateral.contractAddress, _collateral.tokenId)
  self.collateralsInLoans[key][_borrower] = _loanId
  self.collateralsInLoansUsed[key][_borrower][_loanId] = True


@internal
def _removeCollateralFromLoan(_borrower: address, _collateral: Collateral, _loanId: uint256):
  key: bytes32 = self._computeCollateralKey(_collateral.contractAddress, _collateral.tokenId)
  self.collateralsInLoansUsed[key][_borrower][_loanId] = False


@internal
def _updateCollaterals(_collateral: Collateral, _toRemove: bool):
  key: bytes32 = self._computeCollateralKey(_collateral.contractAddress, _collateral.tokenId)

  if key not in self.collateralKeys and not _toRemove:
    self.collateralKeys.append(key)
    self.collateralsUsed[key] = True
    self.collateralsData[key] = _collateral
  elif key in self.collateralKeys:
    self.collateralsUsed[key] = not _toRemove

  if _collateral.tokenId not in self.collateralsIdsByAddress[_collateral.contractAddress] and not _toRemove:
    self.collateralsIdsByAddress[_collateral.contractAddress].append(_collateral.tokenId)


@internal
def _addLoan(_borrower: address, _loan: Loan) -> bool:
    if _loan.id == len(self.loans[_borrower]):
        self.loans[_borrower].append(_loan)
        self.ongoingLoans[_borrower] += 1
        return True
    return False


##### EXTERNAL METHODS #####

@external
def __init__():
    self.owner = msg.sender


@external
def proposeOwner(_address: address):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _address != empty(address), "_address it the zero address"
    assert self.owner != _address, "proposed owner addr is the owner"
    assert self.proposedOwner != _address, "proposed owner addr is the same"

    self.proposedOwner = _address

    log OwnerProposed(
        self.owner,
        _address,
        self.owner,
        _address,
        ILendingPoolPeripheral(
            ILoansPeripheral(self.loansPeripheral).lendingPoolPeripheralContract()
        ).erc20TokenContract()
    )


@external
def claimOwnership():
    assert msg.sender == self.proposedOwner, "msg.sender is not the proposed"

    log OwnershipTransferred(
        self.owner,
        self.proposedOwner,
        self.owner,
        self.proposedOwner,
        ILendingPoolPeripheral(
            ILoansPeripheral(self.loansPeripheral).lendingPoolPeripheralContract()
        ).erc20TokenContract()
    )

    self.owner = self.proposedOwner
    self.proposedOwner = empty(address)


@external
def setLoansPeripheral(_address: address):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _address != empty(address), "_address is the zero address"
    assert _address != self.loansPeripheral, "new loans addr is the same"

    log LoansPeripheralAddressSet(
        ILendingPoolPeripheral(
            ILoansPeripheral(_address).lendingPoolPeripheralContract()
        ).erc20TokenContract(),
        self.loansPeripheral,
        _address,
        ILendingPoolPeripheral(
            ILoansPeripheral(_address).lendingPoolPeripheralContract()
        ).erc20TokenContract()
    )

    self.loansPeripheral = _address


@view
@external
def isLoanCreated(_borrower: address, _loanId: uint256) -> bool:
    return self._isLoanCreated(_borrower, _loanId)


@view
@external
def isLoanStarted(_borrower: address, _loanId: uint256) -> bool:
    return self._isLoanStarted(_borrower, _loanId)


@view
@external
def getLoanAmount(_borrower: address, _loanId: uint256) -> uint256:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].amount
    return 0


@view
@external
def getLoanMaturity(_borrower: address, _loanId: uint256) -> uint256:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].maturity
    return 0


@view
@external
def getLoanInterest(_borrower: address, _loanId: uint256) -> uint256:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].interest
    return 0


@view
@external
def getLoanCollaterals(_borrower: address, _loanId: uint256) -> DynArray[Collateral, 100]:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].collaterals
    return empty(DynArray[Collateral, 100])


@view
@external
def getLoanStartTime(_borrower: address, _loanId: uint256) -> uint256:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].startTime
    return max_value(uint256)


@view
@external
def getLoanPaidPrincipal(_borrower: address, _loanId: uint256) -> uint256:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].paidPrincipal
    return 0


@view
@external
def getLoanPaidInterestAmount(_borrower: address, _loanId: uint256) -> uint256:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].paidInterestAmount
    return 0


@view
@external
def getLoanStarted(_borrower: address, _loanId: uint256) -> bool:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].started
    return False


@view
@external
def getLoanInvalidated(_borrower: address, _loanId: uint256) -> bool:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].invalidated
    return False


@view
@external
def getLoanPaid(_borrower: address, _loanId: uint256) -> bool:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].paid
    return False


@view
@external
def getLoanDefaulted(_borrower: address, _loanId: uint256) -> bool:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].defaulted
    return False


@view
@external
def getLoanCanceled(_borrower: address, _loanId: uint256) -> bool:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].canceled
    return False


@view
@external
def getPendingLoan(_borrower: address, _loanId: uint256) -> Loan:
  if self._isLoanCreated(_borrower, _loanId) and not self._isLoanStarted(_borrower, _loanId) and not self._isLoanInvalidated(_borrower, _loanId):
    return self.loans[_borrower][_loanId]
  return empty(Loan)


@view
@external
def getLoan(_borrower: address, _loanId: uint256) -> Loan:
  if self._isLoanStarted(_borrower, _loanId) or self._isLoanInvalidated(_borrower, _loanId):
    return self.loans[_borrower][_loanId]
  return empty(Loan)


@view
@external
def getHighestSingleCollateralLoan() -> Loan:
    return self.topStats.highestSingleCollateralLoan


@view
@external
def getHighestCollateralBundleLoan() -> Loan:
    return self.topStats.highestCollateralBundleLoan


@view
@external
def getHighestRepayment() -> Loan:
    return self.topStats.highestRepayment


@view
@external
def getHighestDefaultedLoan() -> Loan:
    return self.topStats.highestDefaultedLoan


@view
@external
def collateralKeysArray() -> DynArray[bytes32, 2**20]:
  return self.collateralKeys


@view
@external
def getCollateralsIdsByAddress(_address: address) -> DynArray[uint256, 2**20]:
  return self.collateralsIdsByAddress[_address]


@external
def addCollateralToLoan(_borrower: address, _collateral: Collateral, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"
    assert self._isLoanCreated(_borrower, _loanId), "loan not found"

    self._addCollateralToLoan(_borrower, _collateral, _loanId)


@external
def removeCollateralFromLoan(_borrower: address, _collateral: Collateral, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"
    assert self._isLoanCreated(_borrower, _loanId), "loan not found"
    
    self._removeCollateralFromLoan(_borrower, _collateral, _loanId)


@external
def updateCollaterals(_collateral: Collateral, _toRemove: bool):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    self._updateCollaterals(_collateral, _toRemove)


@external
def addLoan(
    _borrower: address,
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100]
) -> uint256:
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    newLoan: Loan = Loan(
        {
            id: len(self.loans[_borrower]),
            amount: _amount,
            interest: _interest,
            maturity: _maturity,
            startTime: 0,
            collaterals: _collaterals,
            paidPrincipal: 0,
            paidInterestAmount: 0,
            started: False,
            invalidated: False,
            paid: False,
            defaulted: False,
            canceled: False,
        }
    )

    result: bool = self._addLoan(_borrower, newLoan)
    if not result:
        raise "adding loan for borrower failed"

    return newLoan.id


@external
def updateLoanStarted(_borrower: address, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    self.loans[_borrower][_loanId].startTime = block.timestamp
    self.loans[_borrower][_loanId].started = True

    self.borrowedAmount[_borrower] += self.loans[_borrower][_loanId].amount

    for collateral in self.loans[_borrower][_loanId].collaterals:
        self.collectionsBorrowedAmount[collateral.contractAddress] += collateral.amount


@external
def updateInvalidLoan(_borrower: address, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    self.loans[_borrower][_loanId].invalidated = True

    self.ongoingLoans[_borrower] -= 1


@external
def updateLoanPaidAmount(_borrower: address, _loanId: uint256, _paidPrincipal: uint256, _paidInterestAmount: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"
  
    self.loans[_borrower][_loanId].paidPrincipal += _paidPrincipal
    self.loans[_borrower][_loanId].paidInterestAmount += _paidInterestAmount


@external
def updatePaidLoan(_borrower: address, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    self.loans[_borrower][_loanId].paid = True

    self.borrowedAmount[_borrower] -= self.loans[_borrower][_loanId].amount

    self.ongoingLoans[_borrower] -= 1

    for collateral in self.loans[_borrower][_loanId].collaterals:
        self.collectionsBorrowedAmount[collateral.contractAddress] -= collateral.amount


@external
def updateDefaultedLoan(_borrower: address, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    self.loans[_borrower][_loanId].defaulted = True

    self.borrowedAmount[_borrower] -= self.loans[_borrower][_loanId].amount

    self.ongoingLoans[_borrower] -= 1

    for collateral in self.loans[_borrower][_loanId].collaterals:
        self.collectionsBorrowedAmount[collateral.contractAddress] -= collateral.amount


@external
def updateCanceledLoan(_borrower: address, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    self.loans[_borrower][_loanId].canceled = True

    self.ongoingLoans[_borrower] -= 1


@external
def updateHighestSingleCollateralLoan(_borrower: address, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"
  
    if len(self.loans[_borrower][_loanId].collaterals) == 1 and self.topStats.highestSingleCollateralLoan.amount < self.loans[_borrower][_loanId].amount:
        self.topStats.highestSingleCollateralLoan = self.loans[_borrower][_loanId]
  

@external
def updateHighestCollateralBundleLoan(_borrower: address, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    if len(self.loans[_borrower][_loanId].collaterals) > 1 and self.topStats.highestCollateralBundleLoan.amount < self.loans[_borrower][_loanId].amount:
        self.topStats.highestCollateralBundleLoan = self.loans[_borrower][_loanId]


@external
def updateHighestRepayment(_borrower: address, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    if self.topStats.highestRepayment.amount < self.loans[_borrower][_loanId].amount:
        self.topStats.highestRepayment = self.loans[_borrower][_loanId]


@external
def updateHighestDefaultedLoan(_borrower: address, _loanId: uint256):
    assert msg.sender == self.loansPeripheral, "msg.sender is not the loans addr"

    if self.topStats.highestDefaultedLoan.amount < self.loans[_borrower][_loanId].amount:
        self.topStats.highestDefaultedLoan = self.loans[_borrower][_loanId]
# @version 0.3.7

"""
@title LoansTmp
@author [Zharta](https://zharta.io/)
@notice The loans contract exists as the main interface to create peer-to-pool NFT-backed loans
@dev Uses a `LoansCore` contract to store state
"""

# Interfaces

interface IERC721:
    def ownerOf(_tokenId: uint256) -> address: view

interface IERC20:
    def balanceOf(_owner: address) -> uint256: view
    def allowance(_owner: address, _operator: address) -> uint256: view

interface ILoansCore:
    def isLoanCreated(_borrower: address, _loanId: uint256) -> bool: view
    def addLoan(_borrower: address, _amount: uint256, _interest: uint256, _maturity: uint256, _collaterals: DynArray[Collateral, 100]) -> uint256: nonpayable
    def addCollateralToLoan(_borrower: address, _collateral: Collateral, _loanId: uint256): nonpayable
    def updateCollaterals(_collateral: Collateral, _value: bool): nonpayable
    def updateLoanStarted(_borrower: address, _loanId: uint256): nonpayable
    def updateHighestSingleCollateralLoan(_borrower: address, _loanId: uint256): nonpayable
    def updateHighestCollateralBundleLoan(_borrower: address, _loanId: uint256): nonpayable
    def getLoan(_borrower: address, _loanId: uint256) -> Loan: view
    def isLoanStarted(_borrower: address, _loanId: uint256) -> bool: view
    def updateLoanPaidAmount(_borrower: address, _loanId: uint256, _amount: uint256, _interestAmount: uint256): nonpayable
    def updatePaidLoan(_borrower: address, _loanId: uint256): nonpayable
    def updateHighestRepayment(_borrower: address, _loanId: uint256): nonpayable
    def updateDefaultedLoan(_borrower: address, _loanId: uint256): nonpayable
    def removeCollateralFromLoan(_borrower: address, _collateral: Collateral, _loanId: uint256): nonpayable
    def updateHighestDefaultedLoan(_borrower: address, _loanId: uint256): nonpayable

interface ICollateralVaultPeripheral:
    def isCollateralApprovedForVault(_borrower: address, _collateralAddress: address, _tokenId: uint256) -> bool: view
    def storeCollateral(_borrower: address, _collateralAddress: address, _tokenId: uint256, _erc20TokenContract: address, _delegations: bool): nonpayable
    def transferCollateralFromLoan(_borrower: address, _collateralAddress: address, _tokenId: uint256, _erc20TokenContract: address): nonpayable
    def setCollateralDelegation(_borrower: address, _collateralAddress: address, _tokenId: uint256, _erc20TokenContract: address, _delegations: bool): nonpayable

interface ILiquidityControls:
    def withinCollectionShareLimit(_collectionAmount: uint256, _collectionAddress: address, _loansCoreContract: address, _lendingPoolCoreContract: address) -> bool: view
    def withinLoansPoolShareLimit(_borrower: address, _amount: uint256, _loansCoreContract: address, _lendingPoolCoreContract: address) -> bool: view

interface IERC20Symbol:
    def symbol() -> String[100]: view

interface ILendingPoolPeripheral:
    def maxFundsInvestable() -> uint256: view 
    def erc20TokenContract() -> address: view
    def sendFundsEth(_to: address, _amount: uint256): nonpayable
    def sendFundsWeth(_to: address, _amount: uint256): nonpayable
    def receiveFundsEth(_borrower: address, _amount: uint256, _rewardsAmount: uint256): payable
    def receiveFundsWeth(_borrower: address, _amount: uint256, _rewardsAmount: uint256): payable
    def lendingPoolCoreContract() -> address: view

interface ILiquidationsPeripheral:
    def addLiquidation(_borrower: address, _loanId: uint256, _erc20TokenContract: address): nonpayable

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


struct EIP712Domain:
    name: String[100]
    version: String[10]
    chain_id: uint256
    verifying_contract: address

struct ReserveMessageContent:
    amount: uint256
    interest: uint256
    maturity: uint256
    collaterals: DynArray[Collateral, 100]
    delegations: DynArray[bool, 100]
    deadline: uint256


# Events

event OwnershipTransferred:
    ownerIndexed: indexed(address)
    proposedOwnerIndexed: indexed(address)
    owner: address
    proposedOwner: address
    erc20TokenContract: address

event OwnerProposed:
    ownerIndexed: indexed(address)
    proposedOwnerIndexed: indexed(address)
    owner: address
    proposedOwner: address
    erc20TokenContract: address

event InterestAccrualPeriodChanged:
    erc20TokenContractIndexed: indexed(address)
    currentValue: uint256
    newValue: uint256
    erc20TokenContract: address

event LendingPoolPeripheralAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address

event CollateralVaultPeripheralAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address

event LiquidationsPeripheralAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address

event LiquidityControlsAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address

event ContractStatusChanged:
    erc20TokenContractIndexed: indexed(address)
    value: bool
    erc20TokenContract: address

event ContractDeprecated:
    erc20TokenContractIndexed: indexed(address)
    erc20TokenContract: address

event LoanCreated:
    walletIndexed: indexed(address)
    wallet: address
    loanId: uint256
    erc20TokenContract: address
    apr: uint256 # calculated from the interest to 365 days, in bps
    amount: uint256
    duration: uint256
    collaterals: DynArray[Collateral, 100]

event LoanPayment:
    walletIndexed: indexed(address)
    wallet: address
    loanId: uint256
    principal: uint256
    interestAmount: uint256
    erc20TokenContract: address

event LoanPaid:
    walletIndexed: indexed(address)
    wallet: address
    loanId: uint256
    erc20TokenContract: address

event LoanDefaulted:
    walletIndexed: indexed(address)
    wallet: address
    loanId: uint256
    amount: uint256
    erc20TokenContract: address

event PaymentSent:
    walletIndexed: indexed(address)
    wallet: address
    amount: uint256

event PaymentReceived:
    walletIndexed: indexed(address)
    wallet: address
    amount: uint256


# Global variables

owner: public(address)
proposedOwner: public(address)

interestAccrualPeriod: public(uint256)

isAcceptingLoans: public(bool)
isDeprecated: public(bool)

loansCoreContract: public(address)
lendingPoolPeripheralContract: public(address)
collateralVaultPeripheralContract: public(address)
liquidationsPeripheralContract: public(address)
liquidityControlsContract: public(address)

collectionsAmount: HashMap[address, uint256] # aux variable

ZHARTA_DOMAIN_NAME: constant(String[6]) = "Zharta"
ZHARTA_DOMAIN_VERSION: constant(String[1]) = "1"

COLLATERAL_TYPE_DEF: constant(String[66]) = "Collateral(address contractAddress,uint256 tokenId,uint256 amount)"
RESERVE_TYPE_DEF: constant(String[227]) = "ReserveMessageContent(address borrower,uint256 amount,uint256 interest,uint256 maturity,Collateral[] collaterals,bool delegations,uint256 deadline,uint256 nonce)" \
                                          "Collateral(address contractAddress,uint256 tokenId,uint256 amount)"
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
COLLATERAL_TYPE_HASH: constant(bytes32) = keccak256(COLLATERAL_TYPE_DEF)
RESERVE_TYPE_HASH: constant(bytes32) = keccak256(RESERVE_TYPE_DEF)

reserve_message_typehash: bytes32
reserve_sig_domain_separator: bytes32

MINIMUM_INTEREST_PERIOD: constant(uint256) = 604800  # 7 days


@external
def __init__(
    _interestAccrualPeriod: uint256,
    _loansCoreContract: address,
    _lendingPoolPeripheralContract: address,
    _collateralVaultPeripheralContract: address
):
    assert _loansCoreContract != empty(address), "address is the zero address"
    assert _lendingPoolPeripheralContract != empty(address), "address is the zero address"
    assert _collateralVaultPeripheralContract != empty(address), "address is the zero address"

    self.owner = msg.sender
    self.interestAccrualPeriod = _interestAccrualPeriod
    self.loansCoreContract = _loansCoreContract
    self.lendingPoolPeripheralContract = _lendingPoolPeripheralContract
    self.collateralVaultPeripheralContract = _collateralVaultPeripheralContract
    self.isAcceptingLoans = True

    self.reserve_sig_domain_separator = keccak256(
        _abi_encode(
            DOMAIN_TYPE_HASH,
            keccak256(ZHARTA_DOMAIN_NAME),
            keccak256(ZHARTA_DOMAIN_VERSION),
            chain.id,
            self
        )
    )


@internal
def _areCollateralsOwned(_borrower: address, _collaterals: DynArray[Collateral, 100]) -> bool:
    for collateral in _collaterals:
        if IERC721(collateral.contractAddress).ownerOf(collateral.tokenId) != _borrower:
            return False
    return True


@view
@internal
def _areCollateralsApproved(_borrower: address, _collaterals: DynArray[Collateral, 100]) -> bool:
    for collateral in _collaterals:
        if not ICollateralVaultPeripheral(self.collateralVaultPeripheralContract).isCollateralApprovedForVault(
            _borrower,
            collateral.contractAddress,
            collateral.tokenId
        ):
            return False
    return True


@pure
@internal
def _collateralsAmounts(_collaterals: DynArray[Collateral, 100]) -> uint256:
    sumAmount: uint256 = 0
    for collateral in _collaterals:
        sumAmount += collateral.amount

    return sumAmount


@internal
def _withinCollectionShareLimit(_collaterals: DynArray[Collateral, 100]) -> bool:
    collections: DynArray[address, 100] = empty(DynArray[address, 100])

    for collateral in _collaterals:
        if collateral.contractAddress not in collections:
            collections.append(collateral.contractAddress)
            self.collectionsAmount[collateral.contractAddress] = 0

        self.collectionsAmount[collateral.contractAddress] += collateral.amount

    for collection in collections:
        result: bool = ILiquidityControls(self.liquidityControlsContract).withinCollectionShareLimit(
            self.collectionsAmount[collection],
            collection,
            self.loansCoreContract,
            ILendingPoolPeripheral(self.lendingPoolPeripheralContract).lendingPoolCoreContract()
        )
        if not result:
            return False

    return True

@pure
@internal
def _loanPayableAmount(
    _amount: uint256,
    _paidAmount: uint256,
    _interest: uint256,
    _maxLoanDuration: uint256,
    _timePassed: uint256,
    _interestAccrualPeriod: uint256
) -> uint256:
    return (_amount - _paidAmount) * (10000 * _maxLoanDuration + _interest * (max(_timePassed + _interestAccrualPeriod, MINIMUM_INTEREST_PERIOD))) / (10000 * _maxLoanDuration)


@pure
@internal
def _computePeriodPassedInSeconds(_recentTimestamp: uint256, _olderTimestamp: uint256, _period: uint256) -> uint256:
    return (_recentTimestamp - _olderTimestamp) - ((_recentTimestamp - _olderTimestamp) % _period)


@internal
def _recoverReserveSigner(
    _borrower: address,
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100],
    _delegations: bool,
    _deadline: uint256,
    _nonce: uint256,
    _v: uint256,
    _r: uint256,
    _s: uint256
) -> address:
    """
        @notice recovers the sender address of the signed reserve function call
    """
    collaterals_data_hash: DynArray[bytes32, 100] = []
    for c in _collaterals:
        collaterals_data_hash.append(keccak256(_abi_encode(COLLATERAL_TYPE_HASH, c.contractAddress, c.tokenId, c.amount)))

    data_hash: bytes32 = keccak256(_abi_encode(
                RESERVE_TYPE_HASH,
                _borrower,
                _amount,
                _interest,
                _maturity,
                keccak256(slice(_abi_encode(collaterals_data_hash), 32*2, 32*len(_collaterals))),
                _delegations,
                _deadline,
                _nonce
                ))

    sig_hash: bytes32 = keccak256(concat(convert("\x19\x01", Bytes[2]), _abi_encode(self.reserve_sig_domain_separator, data_hash)))
    signer: address = ecrecover(sig_hash, _v, _r, _s)

    return signer


@internal
def _reserve(
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100],
    _delegations: bool,
    _deadline: uint256,
    _nonce: uint256,
    _v: uint256,
    _r: uint256,
    _s: uint256
) -> uint256:
    assert not self.isDeprecated, "contract is deprecated"
    assert self.isAcceptingLoans, "contract is not accepting loans"
    assert block.timestamp < _maturity, "maturity is in the past"
    assert block.timestamp <= _deadline, "deadline has passed"
    assert self._areCollateralsOwned(msg.sender, _collaterals), "msg.sender does not own all NFTs"
    assert self._areCollateralsApproved(msg.sender, _collaterals) == True, "not all NFTs are approved"
    assert self._collateralsAmounts(_collaterals) == _amount, "amount in collats != than amount"
    assert ILendingPoolPeripheral(self.lendingPoolPeripheralContract).maxFundsInvestable() >= _amount, "insufficient liquidity"

    assert ILiquidityControls(self.liquidityControlsContract).withinLoansPoolShareLimit(
        msg.sender,
        _amount,
        self.loansCoreContract,
        self.lendingPoolPeripheralContract
    ), "max loans pool share surpassed"
    assert self._withinCollectionShareLimit(_collaterals), "max collection share surpassed"

    assert not ILoansCore(self.loansCoreContract).isLoanCreated(msg.sender, _nonce), "loan already created"
    if _nonce > 0:
        assert ILoansCore(self.loansCoreContract).isLoanCreated(msg.sender, _nonce - 1), "loan is not sequential"
    
    signer: address = self._recoverReserveSigner(msg.sender, _amount, _interest, _maturity, _collaterals, _delegations, _deadline, _nonce, _v, _r, _s)
    assert signer == self.owner, "invalid message signature"

    newLoanId: uint256 = ILoansCore(self.loansCoreContract).addLoan(
        msg.sender,
        _amount,
        _interest,
        _maturity,
        _collaterals
    )

    for collateral in _collaterals:
        ILoansCore(self.loansCoreContract).addCollateralToLoan(msg.sender, collateral, newLoanId)
        ILoansCore(self.loansCoreContract).updateCollaterals(collateral, False)

        ICollateralVaultPeripheral(self.collateralVaultPeripheralContract).storeCollateral(
            msg.sender,
            collateral.contractAddress,
            collateral.tokenId,
            ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
            _delegations
        )

    log LoanCreated(
        msg.sender,
        msg.sender,
        newLoanId,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
        _interest * 365 * 86400 / (_maturity - block.timestamp),
        _amount,
        _maturity - block.timestamp,
        _collaterals
    )

    ILoansCore(self.loansCoreContract).updateLoanStarted(msg.sender, newLoanId)
    ILoansCore(self.loansCoreContract).updateHighestSingleCollateralLoan(msg.sender, newLoanId)
    ILoansCore(self.loansCoreContract).updateHighestCollateralBundleLoan(msg.sender, newLoanId)

    return newLoanId


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
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )


@external
def claimOwnership():
    assert msg.sender == self.proposedOwner, "msg.sender is not the proposed"

    log OwnershipTransferred(
        self.owner,
        self.proposedOwner,
        self.owner,
        self.proposedOwner,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )

    self.owner = self.proposedOwner
    self.proposedOwner = empty(address)


@external
def changeInterestAccrualPeriod(_value: uint256):
    """
    @notice Sets the interest accrual period, considered on loan payment calculations
    @dev Logs `InterestAccrualPeriodChanged` event
    @param _value The interest accrual period in seconds
    """
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _value != self.interestAccrualPeriod, "_value is the same"

    log InterestAccrualPeriodChanged(
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
        self.interestAccrualPeriod,
        _value,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )

    self.interestAccrualPeriod = _value


@external
def setLendingPoolPeripheralAddress(_address: address):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _address != empty(address), "_address is the zero address"
    assert _address.is_contract, "_address is not a contract"
    assert self.lendingPoolPeripheralContract != _address, "new LPPeriph addr is the same"

    log LendingPoolPeripheralAddressSet(
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
        self.lendingPoolPeripheralContract,
        _address,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )

    self.lendingPoolPeripheralContract = _address


@external
def setCollateralVaultPeripheralAddress(_address: address):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _address != empty(address), "_address is the zero address"
    assert _address.is_contract, "_address is not a contract"
    assert self.collateralVaultPeripheralContract != _address, "new LPCore addr is the same"

    log CollateralVaultPeripheralAddressSet(
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
        self.collateralVaultPeripheralContract,
        _address,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )

    self.collateralVaultPeripheralContract = _address


@external
def setLiquidationsPeripheralAddress(_address: address):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _address != empty(address), "_address is the zero address"
    assert _address.is_contract, "_address is not a contract"
    assert self.liquidationsPeripheralContract != _address, "new LPCore addr is the same"

    log LiquidationsPeripheralAddressSet(
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
        self.liquidationsPeripheralContract,
        _address,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )

    self.liquidationsPeripheralContract = _address


@external
def setLiquidityControlsAddress(_address: address):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _address != empty(address), "_address is the zero address"
    assert _address.is_contract, "_address is not a contract"
    assert _address != self.liquidityControlsContract, "new value is the same"

    log LiquidityControlsAddressSet(
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
        self.liquidityControlsContract,
        _address,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )

    self.liquidityControlsContract = _address


@external
def changeContractStatus(_flag: bool):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert self.isAcceptingLoans != _flag, "new contract status is the same"

    self.isAcceptingLoans = _flag

    log ContractStatusChanged(
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
        _flag,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )


@external
def deprecate():
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert not self.isDeprecated, "contract is already deprecated"

    self.isDeprecated = True
    self.isAcceptingLoans = False

    log ContractDeprecated(
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )


@view
@external
def erc20TokenSymbol() -> String[100]:
    return IERC20Symbol(ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()).symbol()


@view
@external
def getLoanPayableAmount(_borrower: address, _loanId: uint256, _timestamp: uint256) -> uint256:
    loan: Loan = ILoansCore(self.loansCoreContract).getLoan(_borrower, _loanId)

    if loan.paid:
        return 0

    if loan.startTime > _timestamp:
        return max_value(uint256)

    if loan.started:
        timePassed: uint256 = self._computePeriodPassedInSeconds(
            _timestamp,
            loan.startTime,
            self.interestAccrualPeriod
        )
        return self._loanPayableAmount(
            loan.amount,
            loan.paidPrincipal,
            loan.interest,
            loan.maturity - loan.startTime,
            timePassed,
            self.interestAccrualPeriod
        )

    return max_value(uint256)


@external
def reserveWeth(
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100],
    _delegations: bool,
    _deadline: uint256,
    _nonce: uint256,
    _v: uint256,
    _r: uint256,
    _s: uint256
) -> uint256:
    """
    @notice Creates a new loan with the defined amount, interest rate and collateral. The message must be signed by the contract owner.
    @dev Logs `LoanCreated` event. The last 3 parameters must match a signature by the contract owner of the implicit message consisting of the remaining parameters, in order for the loan to be created
    @param _amount The loan amount in wei
    @param _interest The interest rate in bps (1/1000) for the loan duration
    @param _maturity The loan maturity in unix epoch format
    @param _collaterals The list of collaterals supporting the loan
    @param _delegations Wether to set the requesting wallet as a delegate for all collaterals
    @param _deadline The deadline of validity for the signed message in unix epoch format
    @param _v recovery id for public key recover
    @param _r r value in ECDSA signature
    @param _s s value in ECDSA signature
    @return The loan id
    """

    newLoanId: uint256 = self._reserve(_amount, _interest, _maturity, _collaterals, _delegations, _deadline, _nonce, _v, _r, _s)

    ILendingPoolPeripheral(self.lendingPoolPeripheralContract).sendFundsWeth(
        msg.sender,
        _amount
    )

    return newLoanId


@external
def reserveEth(
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100],
    _delegations: bool,
    _deadline: uint256,
    _nonce: uint256,
    _v: uint256,
    _r: uint256,
    _s: uint256
) -> uint256:
    """
    @notice Creates a new loan with the defined amount, interest rate and collateral. The message must be signed by the contract owner.
    @dev Logs `LoanCreated` event. The last 3 parameters must match a signature by the contract owner of the implicit message consisting of the remaining parameters, in order for the loan to be created
    @param _amount The loan amount in wei
    @param _interest The interest rate in bps (1/1000) for the loan duration
    @param _maturity The loan maturity in unix epoch format
    @param _collaterals The list of collaterals supporting the loan
    @param _delegations Wether to set the requesting wallet as a delegate for all collaterals
    @param _deadline The deadline of validity for the signed message in unix epoch format
    @param _v recovery id for public key recover
    @param _r r value in ECDSA signature
    @param _s s value in ECDSA signature
    @return The loan id
    """

    newLoanId: uint256 = self._reserve(_amount, _interest, _maturity, _collaterals, _delegations, _deadline, _nonce, _v, _r, _s)

    ILendingPoolPeripheral(self.lendingPoolPeripheralContract).sendFundsEth(
        msg.sender,
        _amount
    )

    return newLoanId


@payable
@external
def pay(_loanId: uint256):

    """
    @notice Closes an active loan by paying the full amount
    @dev Logs the `LoanPayment` and `LoanPaid` events. The associated `LendingPoolCore` contract must be approved for the payment amount
    @param _loanId The id of the loan to settle
    """

    receivedAmount: uint256 = msg.value
    assert ILoansCore(self.loansCoreContract).isLoanStarted(msg.sender, _loanId), "loan not found"
    
    loan: Loan = ILoansCore(self.loansCoreContract).getLoan(msg.sender, _loanId)
    assert block.timestamp <= loan.maturity, "loan maturity reached"
    assert not loan.paid, "loan already paid"

    # compute days passed in seconds
    timePassed: uint256 = self._computePeriodPassedInSeconds(
        block.timestamp,
        loan.startTime,
        self.interestAccrualPeriod
    )

    # pro-rata computation of max amount payable based on actual loan duration in days
    paymentAmount: uint256 = self._loanPayableAmount(
        loan.amount,
        loan.paidPrincipal,
        loan.interest,
        loan.maturity - loan.startTime,
        timePassed,
        self.interestAccrualPeriod
    )

    erc20TokenContract: address = ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    excessAmount: uint256 = 0

    if receivedAmount > 0:
        assert receivedAmount >= paymentAmount, "insufficient value received"
        excessAmount = receivedAmount - paymentAmount
        log PaymentReceived(msg.sender, msg.sender, receivedAmount)
    else:
        assert IERC20(erc20TokenContract).balanceOf(msg.sender) >= paymentAmount, "insufficient balance"
        assert IERC20(erc20TokenContract).allowance(
                msg.sender,
                ILendingPoolPeripheral(self.lendingPoolPeripheralContract).lendingPoolCoreContract()
        ) >= paymentAmount, "insufficient allowance"

    paidInterestAmount: uint256 = paymentAmount - loan.amount

    ILoansCore(self.loansCoreContract).updateLoanPaidAmount(msg.sender, _loanId, loan.amount, paidInterestAmount)
    ILoansCore(self.loansCoreContract).updatePaidLoan(msg.sender, _loanId)
    ILoansCore(self.loansCoreContract).updateHighestRepayment(msg.sender, _loanId)

    if receivedAmount > 0:
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).receiveFundsEth(msg.sender, loan.amount, paidInterestAmount, value=paymentAmount)
        log PaymentSent(self.lendingPoolPeripheralContract, self.lendingPoolPeripheralContract, paymentAmount)
    else:
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).receiveFundsWeth(msg.sender, loan.amount, paidInterestAmount)

    for collateral in loan.collaterals:
        ILoansCore(self.loansCoreContract).removeCollateralFromLoan(msg.sender, collateral, _loanId)
        ILoansCore(self.loansCoreContract).updateCollaterals(collateral, True)

        ICollateralVaultPeripheral(self.collateralVaultPeripheralContract).transferCollateralFromLoan(
            msg.sender,
            collateral.contractAddress,
            collateral.tokenId,
            erc20TokenContract
        )

    if excessAmount > 0:
        send(msg.sender, excessAmount)
        log PaymentSent(msg.sender, msg.sender,excessAmount)

    log LoanPayment(
        msg.sender,
        msg.sender,
        _loanId,
        loan.amount,
        paidInterestAmount,
        erc20TokenContract
    )
    
    log LoanPaid(
        msg.sender,
        msg.sender,
        _loanId,
        erc20TokenContract
    )


@external
def settleDefault(_borrower: address, _loanId: uint256):
    """
    @notice Settles an active loan as defaulted
    @dev Logs the `LoanDefaulted` event, removes the collaterals from the loan and creates a liquidation
    @param _borrower The wallet address of the borrower
    @param _loanId The id of the loan to settle
    """
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert ILoansCore(self.loansCoreContract).isLoanStarted(_borrower, _loanId), "loan not found"
    
    loan: Loan = ILoansCore(self.loansCoreContract).getLoan(_borrower, _loanId)
    assert not loan.paid, "loan already paid"
    assert block.timestamp > loan.maturity, "loan is within maturity period"
    assert self.liquidationsPeripheralContract != empty(address), "BNPeriph is the zero address"

    ILoansCore(self.loansCoreContract).updateDefaultedLoan(_borrower, _loanId)
    ILoansCore(self.loansCoreContract).updateHighestDefaultedLoan(_borrower, _loanId)

    for collateral in loan.collaterals:
        ILoansCore(self.loansCoreContract).removeCollateralFromLoan(_borrower, collateral, _loanId)
        ILoansCore(self.loansCoreContract).updateCollaterals(collateral, True)

    ILiquidationsPeripheral(self.liquidationsPeripheralContract).addLiquidation(
        _borrower,
        _loanId,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )

    log LoanDefaulted(
        _borrower,
        _borrower,
        _loanId,
        loan.amount,
        ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract()
    )


@external
def setDelegation(_loanId: uint256, _collateralAddress: address, _tokenId: uint256, _value: bool):

    """
    @notice Sets / unsets a delegation for some collateral of a given loan. Only available to unpaid loans until maturity is reached
    @param _loanId The id of the loan to settle
    @param _collateralAddress The contract address of the collateral
    @param _tokenId The token id of the collateral
    @param _value Wether to set or unset the token delegation
    """

    loan: Loan = ILoansCore(self.loansCoreContract).getLoan(msg.sender, _loanId)
    assert loan.amount > 0, "invalid loan id"
    assert block.timestamp <= loan.maturity, "loan maturity reached"
    assert not loan.paid, "loan already paid"
    
    for collateral in loan.collaterals:
        if collateral.contractAddress ==_collateralAddress and collateral.tokenId == _tokenId:
            ICollateralVaultPeripheral(self.collateralVaultPeripheralContract).setCollateralDelegation(
                msg.sender,
                _collateralAddress,
                _tokenId,
                ILendingPoolPeripheral(self.lendingPoolPeripheralContract).erc20TokenContract(),
                _value
            )
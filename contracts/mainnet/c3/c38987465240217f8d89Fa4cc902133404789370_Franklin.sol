// contracts/Franklin.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "IERC20Upgradeable.sol";
import "SafeERC20Upgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "PausableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "ERC2771ContextUpgradeable.sol";
import "FranklinTokenWhitelist.sol";
import "IFranklinTokenWhitelist.sol";

/// @title Franklin
/// @author Franklin Systems Inc.
/** @notice

**/
/** @dev
    NEED TO UPDATE PERMISSIONS TO FIT BETA USERS (OWNER VS ADMIN)
**/

contract Franklin is
    OwnableUpgradeable,
    ERC2771ContextUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ============ EVENTS ============
    /// @notice Emits address added to admin permissions
    event AdminAdded(address _admin);
    /// @notice Emits address removed from admin permissions
    event AdminRemoved(address _admin);
    /// @notice Emits address added as a worker, eligible for payroll
    event WorkerAdded(address _worker);
    /// @notice Emits addresses added as workers, eligible for payroll
    event WorkersBulkAdded(address[] _workerAddresses);
    /// @notice Emits worker address and their last day
    event WorkerTerminated(address _worker, uint256 _lastDay);
    /// @notice Emits amount and token address deposited into static treasury
    event StaticDeposit(uint256 _amount, address _token);
    /// @notice Emits amount & token address deposited for streaming treausry
    event StreamingDeposit(uint256 _amount, address _token);
    /// @notice Emits amount and token address withdrawn from nonstreaming treasury
    event StaticWithdrawal(uint256 _amount, address _token);
    // @notice Emits amount and token address withdrawn from streaming treasury
    event StreamingWithdrawal(uint256 _amount, address _token);
    /// @notice Emits old address and new address for a worker when updated
    event WorkerAddressUpdated(address _oldAddress, address _newAddress);
    /// @notice Emits arrays of payroll information after successful execution
    event WorkersBulkPaid(
        address[] _workerAddresses,
        address[] _tokenAddresses,
        uint256[] _amounts
    );
    /** @notice
        Emits information of funds transfered out of contract ownership when a
        _worker claims their Payroll.
    **/
    event PayrollClaimed(address _worker, uint256 _amount, address _token);

    /// @notice Emits details of changing balances in the Franklin ecosystem
    event TransferToWorkerBalance(
        uint256 _amount,
        address _worker,
        address _token
    );

    /// @notice Emits details of a transfer directly to a worker's wallet
    event DirectTransfer(uint256 _amount, address _worker, address _token);

    /// @notice Emits details of a new stream that has been created
    event StreamCreated(
        address _worker,
        address _token,
        uint256 _start,
        uint256 _end,
        uint256 _rate
    );

    /// @notice Emits details of a stream which has been updated
    event StreamEdited(
        address _worker,
        address _token,
        uint256 _start,
        uint256 _end,
        uint256 _rate
    );
    /// @notice Emits details of a stream which has been terminated
    event StreamEnded(address _worker, address _token, uint256 _end);

    /// @notice Emits details of a stream which has been deleted
    event StreamDeleted(address _worker, address _token);

    // ============ STORAGE VARIABLES ============

    /// @dev FranklinTokenWhitelist contract managing approved tokens, defined in initialize
    IFranklinTokenWhitelist tokenWhiteList;

    /// @dev Mapping for managing admin permissions
    mapping(address => bool) private admins;

    /// @dev Mapping for managing workers
    mapping(address => bool) private workers;

    /// @dev Treasury struct managing company treasury per _token
    /// @param staticBalance is the account of funds not allocated to streaming
    /// @param settledStreamingBalance is the account of settled funds for streaming
    /** @param workersWithStream is an array of workers that have a payroll
               stream in the associated token */
    struct Treasury {
        uint256 staticBalance;
        uint256 settledStreamingBalance;
        address[] workersWithStream;
    }

    /// @dev A worker's balance combining settled and streaming funds (per _token)
    /// @param settled is the account of funds owned by a worker not in a stream
    /** @param streamIndex is the location of the worker in the associated
               treasury.workersWithStream array if they exist*/
    struct Balance {
        uint256 settled;
        Stream current;
        Stream next;
        uint256 streamIndex;
    }

    /// @dev Represents a payroll stream that is part of a worker's balance
    struct Stream {
        uint256 start;
        uint256 end;
        uint256 withdrawn;
        uint256 rate;
    }

    /** @dev
        Mapping to manage balances.
        The first address in the mapping is the worker address, the second
        address is the ERC20 address of the _token. It returns the Balance
        struct for that _worker for that _token */
    mapping(address => mapping(address => Balance)) private tokenBalance;

    /** @dev
        Mapping to manage the Payroll Treasury owned by the organization.
        This may be different than the total funds "owned" by the contract
        as Users will not instantly claim payroll. Takes the address of the
        ERC20 _token and returns the Treasury struct representing the balance
        of that _token */
    mapping(address => Treasury) private tokenTreasury;

    // ============ MODIFIERS ============

    modifier onlyWorker() {
        _isWorker();
        _;
    }

    function _isWorker() internal view {
        require(workers[_msgSender()], "Must be a worker");
    }

    modifier onlyAdminOrOwner() {
        _isAdminOrOwner();
        _;
    }

    function _isAdminOrOwner() internal view {
        address owner = owner();
        require(
            admins[_msgSender()] || _msgSender() == owner,
            "Must be admin or owner"
        );
    }

    modifier onlyApprovedTokens(address _token) {
        _isApprovedToken(_token);
        _;
    }

    function _isApprovedToken(address _token) internal view {
        bool approved = tokenWhiteList.isApprovedToken(_token);
        require(approved, "Token is not approved");
    }

    modifier onlyExistingWorker(address _worker) {
        _isExistingWorker(_worker);
        _;
    }

    function _isExistingWorker(address _worker) internal view {
        require(workers[_worker], "Worker does not exist");
    }

    // ============ CONSTRUCTOR ============
    constructor() {
        _disableInitializers();
    }

    // ============ INITIALIZERS ============

    /// @notice Called by the proxy when it is deployed
    /// @param forwarder The trusted forwarder for the proxy initializing
    /// @param tokenWhiteListAddress The address of the FranklinTokenWhitelist contract
    function initialize(address forwarder, address tokenWhiteListAddress)
        public
        initializer
    {
        require(forwarder != address(0), "No 0x0 address");
        require(forwarder != address(this), "Cant be this contract");
        require(tokenWhiteListAddress != address(0), "No 0x0 address");
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ERC2771Context_init(forwarder);
        tokenWhiteList = IFranklinTokenWhitelist(tokenWhiteListAddress);
    }

    /// @notice Overrides UUPS implementation to set upgrade permissions
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// Protect owner by overriding renounceOwnership
    function renounceOwnership() public virtual override {
        revert("Cant renounce");
    }

    // ============ VIEW FUNCTIONS ============

    /// @notice Returns True if address is a worker, False otherwise
    /// @param _worker The address being checked for worker permissions
    function isWorker(address _worker)
        external
        view
        onlyAdminOrOwner
        returns (bool)
    {
        return (workers[_worker]);
    }

    /// @notice Returns True if address is an admin, False otherwise
    /// @param _admin The address being checked for admin permissions
    function isAdmin(address _admin)
        external
        view
        onlyAdminOrOwner
        returns (bool)
    {
        return (admins[_admin]);
    }

    /// @notice Returns True if token is approved, False otherwise
    /// @param _token The address being checked for token approval
    function isApprovedToken(address _token)
        external
        view
        onlyAdminOrOwner
        returns (bool)
    {
        return (tokenWhiteList.isApprovedToken(_token));
    }

    /** @notice
        Gets the quantity of funds in the treasury for the requested ERC20
        _token, including the streaming and static treasury balances */
    /// @param _token The address of the ERC20 _token contract
    /// @return The quantity of funds in the treasury for the requested _token
    function getTotalTreasury(address _token)
        external
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        return (getStreamingTreasury(_token) + getStaticTreasury(_token));
    }

    /// @notice Provides the quantity of funds not being used for streams
    /// @param _token The address of the ERC20 _token contract
    /// @return The quantity of funds in the static treasury
    function getStaticTreasury(address _token)
        public
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        return (tokenTreasury[_token].staticBalance);
    }

    /// @notice Provides the quantity of funds available for streaming payroll
    /// @param _token The address of the ERC20 _token contract
    /// @return The quantity of funds in the streaming treasury
    function getStreamingTreasury(address _token)
        public
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        Treasury storage treasury = tokenTreasury[_token];
        address[] storage workerArray = treasury.workersWithStream;
        uint256 streamed = 0;

        /* For each worker that has a stream of the associated token,
           sum the value streamed and add to the `streamed` var which will be
           subtracted from the settled amount to get the balance*/
        for (uint256 i = 1; i < workerArray.length; ) {
            Balance storage b = tokenBalance[workerArray[i]][_token];
            Stream storage current = b.current;
            Stream storage next = b.next;

            if (current.start < block.timestamp) {
                //check if current stream has ended
                if (current.end < block.timestamp) {
                    // add value streamed in current stream
                    streamed += (current.end - current.start) * current.rate;
                    //check if next stream has started
                    if (next.start < block.timestamp) {
                        //check if next stream has ended
                        if (next.end < block.timestamp) {
                            // add value of "next" stream to streamed
                            streamed += (next.end - next.start) * next.rate;
                        } else {
                            // if next hasn't ended, add the amount streamed up to now
                            streamed +=
                                (block.timestamp - next.start) *
                                next.rate;
                        }
                    }
                } else {
                    streamed +=
                        (block.timestamp - current.start) *
                        current.rate;
                }
            }
            unchecked {
                i++;
            }
        }

        return (treasury.settledStreamingBalance - streamed);
    }

    /// @notice Provides the current _rate that funds are streamed out of the Treasury
    /// @param _token The address of the ERC20 _token contract
    /// @return The _rate funds are streaming out of the treasury
    function getStreamingTreasuryRate(address _token)
        external
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        Treasury storage t = tokenTreasury[_token];
        address[] memory workerArray = t.workersWithStream;
        uint256 totalRate = 0;

        for (uint256 i = 1; i < workerArray.length; ) {
            Balance storage b = tokenBalance[workerArray[i]][_token];
            // check if current stream is in effect (assumes started or rate = 0);
            if (
                b.current.start < block.timestamp &&
                block.timestamp < b.current.end
            ) {
                totalRate += b.current.rate;
            } else if (
                b.next.start < block.timestamp && block.timestamp < b.next.end
            ) {
                totalRate += b.next.rate;
            }
            unchecked {
                i++;
            }
        }

        return (totalRate);
    }

    /// @notice Allows workers to check their accumulated payroll by token
    /// @param _token The token address for which they are checking payroll
    /// @return The quantity of payroll accumulated in the specified token
    function getPayrollAsWorker(address _token)
        external
        view
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        return (getSettledBalance(_msgSender(), _token) +
            getStreamBalance(_msgSender(), _token));
    }

    /// @notice Provides the settled balance of a worker
    /// @param _worker The address of the worker being looked up
    /// @param _token The address of the token being looked up
    /// @return The settled balance of the specified token for that worker
    function getSettledBalance(address _worker, address _token)
        public
        view
        onlyWorker
        onlyExistingWorker(_worker)
        returns (uint256)
    {
        return (tokenBalance[_worker][_token].settled);
    }

    /// @notice Provides the streaming balance of a worker
    /// @param _worker The address of the worker being looked up
    /// @param _token The address of the _oken being looked up
    /// @return The stream balance of the specified token for that worker
    function getStreamBalance(address _worker, address _token)
        public
        view
        onlyWorker
        onlyExistingWorker(_worker)
        returns (uint256)
    {
        uint256 currentBalance = _getCurrentStreamBalance(_worker, _token);
        // nextBalance > 0 only if current stream balance has expired
        uint256 nextBalance = _getNextStreamBalance(_worker, _token);

        return (currentBalance + nextBalance);
    }

    /// @notice Gets the balance of balance.current
    /// @param _worker The address of the worker being looked up
    /// @param _token The address of the token being looked up
    /// @return Value of balance.current stream for defined worker/token
    function _getCurrentStreamBalance(address _worker, address _token)
        internal
        view
        returns (uint256)
    {
        Balance storage b = tokenBalance[_worker][_token];
        Stream storage current = b.current; // gets current stream object

        if (current.end < block.timestamp) {
            return ((current.end - current.start) *
                current.rate -
                current.withdrawn);
        } else if (
            current.start < block.timestamp && block.timestamp < current.end
        ) {
            return ((block.timestamp - current.start) *
                current.rate -
                current.withdrawn);
        }
        return (0);
    }

    /** @notice Gets the balance of balance.next. This can be non-zero when
        the current stream has ended and the next stream is accruing value.
        The balance object isn't always immediately updated so this function
        allows us to check if the balance.next stream is accruing value. */
    /// @param _worker The address of the worker being looked up
    /// @param _token The address of the _oken being looked up
    /// @return Value of balance.current stream for defined worker/token
    function _getNextStreamBalance(address _worker, address _token)
        internal
        view
        returns (uint256)
    {
        Balance storage b = tokenBalance[_worker][_token];
        Stream storage next = b.next;

        //check if next stream has ended
        if (next.end < block.timestamp) {
            return ((next.end - next.start) * next.rate - next.withdrawn);
        } else if (next.start < block.timestamp && block.timestamp < next.end) {
            return ((block.timestamp - next.start) *
                next.rate -
                next.withdrawn);
        }

        return (0);
    }

    /// @notice gets the parameters of the current stream in a worker's balance
    /// @param _worker The worker for which you are checking stream parameters
    /// @param _token The token for the balance being checked
    function getCurrentStream(address _worker, address _token)
        external
        view
        onlyAdminOrOwner
        onlyExistingWorker(_worker)
        onlyApprovedTokens(_token)
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Stream storage current = tokenBalance[_worker][_token].current;
        return (current.start, current.end, current.withdrawn, current.rate);
    }

    /// @notice gets the parameters of the next stream in a worker's balance
    /// @param _worker The worker for which you are checking stream parameters
    /// @param _token The token for the balance being checked
    function getNextStream(address _worker, address _token)
        external
        view
        onlyAdminOrOwner
        onlyExistingWorker(_worker)
        onlyApprovedTokens(_token)
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Stream storage next = tokenBalance[_worker][_token].next;
        return (next.start, next.end, next.withdrawn, next.rate);
    }

    /** @notice
        Allows the owner and admin to check payroll accumulated by a specific
        worker, includes settled and streaming balance */
    /// @param _worker The wallet address of the worker requested
    /// @param _token The token address which they are querying
    /// @return The quantity of payroll owed to a worker in the specified token
    function getPayrollAsAdminOrOwner(address _worker, address _token)
        external
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
        returns (uint256)
    {
        return (getSettledBalance(_worker, _token) +
            getStreamBalance(_worker, _token));
    }

    // ============ Public Effects & Interactions Functions ============

    /*** Admin Functions ***/

    /// @notice Adds an address to admin permissions for this contract
    /// @param _admin The address added to admin permissions
    function addAdmin(address _admin) external whenNotPaused onlyOwner {
        require(_admin != address(this), "Cant be this contract");
        require(!admins[_admin], "Admin exists");
        require(_admin != address(0), "No 0x0 address");

        admins[_admin] = true;

        if (!workers[_admin]) {
            workers[_admin] = true;
        }

        emit AdminAdded(_admin);
    }

    /// @notice Removes an address from admin permissions for this contract
    /// @param _admin The address removed from admin permissions
    function removeAdmin(address _admin) external whenNotPaused onlyOwner {
        require(admins[_admin] == true, "Admin doesnt exist");

        admins[_admin] = false;

        emit AdminRemoved(_admin);
    }

    /*** Worker Management ***/

    /// @notice Adds workers address so that it is eligible for payroll
    /// @param _worker The address of the worker being added
    function addWorker(address _worker)
        external
        whenNotPaused
        onlyAdminOrOwner
    {
        require(_worker != address(this), "Cant be this contract");
        require(!workers[_worker], "Worker exists");
        require(_worker != address(0), "No 0x0 address");

        workers[_worker] = true;

        emit WorkerAdded(_worker);
    }

    /// @notice Bulk adds workers so they are eligible for payroll. Max 250 at once
    /// @param _workerAddresses Array of worker addresses being added
    function bulkAddWorkers(address[] calldata _workerAddresses)
        external
        whenNotPaused
        onlyAdminOrOwner
    {
        require(_workerAddresses.length < 250, "Max add is 250");
        for (uint256 i = 0; i < _workerAddresses.length; ) {
            require(!workers[_workerAddresses[i]], "Worker exists");
            require(_workerAddresses[i] != address(0), "No 0x0 address");

            workers[_workerAddresses[i]] = true;
            unchecked {
                i++;
            }
        }

        emit WorkersBulkAdded(_workerAddresses);
    }

    /// @notice Removes a worker from the system. Sends all earned funds earned by their last day to their wallet
    /// @param _worker The worker being removed
    /// @param _lastDay When the worker stops earning funds
    function terminateWorker(address _worker, uint256 _lastDay)
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyExistingWorker(_worker)
    {
        address[] memory approvedTokens = tokenWhiteList.getApprovedTokens();
        // get total balance for each token and force send to their wallet
        for (uint256 i = 0; i < approvedTokens.length; ) {
            Balance storage balance = tokenBalance[_worker][approvedTokens[i]];
            Stream storage current = balance.current;
            Stream storage next = balance.next;
            uint256 streamBalance = 0;
            Treasury storage treasury = tokenTreasury[approvedTokens[i]];

            if (current.start < _lastDay) {
                // get value in current stream
                if (current.end >= _lastDay) {
                    uint256 quantity = (_lastDay - current.start) *
                        current.rate -
                        current.withdrawn;
                    streamBalance += quantity;
                    treasury.settledStreamingBalance -=
                        quantity +
                        current.withdrawn;
                } else if (current.end < _lastDay) {
                    uint256 quantity = (current.end - current.start) *
                        current.rate -
                        current.withdrawn;
                    streamBalance += quantity;
                    treasury.settledStreamingBalance -=
                        quantity +
                        current.withdrawn;
                }
                // get value in next stream
                if (next.start < _lastDay && next.end >= _lastDay) {
                    uint256 quantity = (_lastDay - next.start) *
                        next.rate -
                        next.withdrawn;
                    streamBalance += quantity;
                    treasury.settledStreamingBalance -=
                        quantity +
                        next.withdrawn;
                } else if (next.end < _lastDay) {
                    uint256 quantity = (next.end - next.start) *
                        next.rate -
                        next.withdrawn;
                    streamBalance += quantity;
                    treasury.settledStreamingBalance -=
                        quantity +
                        next.withdrawn;
                }
            }
            uint256 totalBalance = balance.settled + streamBalance;
            delete (tokenBalance[_worker][approvedTokens[i]]);
            IERC20Upgradeable(approvedTokens[i]).safeTransfer(
                _worker,
                totalBalance
            );
            unchecked {
                i++;
            }
        }
        workers[_worker] = false;

        emit WorkerTerminated(_worker, _lastDay);
    }

    /** @notice
        Updates an workers wallet address and transfers payroll from the
        previous wallet address to the new wallet address. This can only be
        called by a worker, and the input is the new address */
    /// @param _newAddress The new address used by the worker
    function updateWorkerAddress(address _newAddress)
        external
        whenNotPaused
        onlyWorker
    {
        require(!workers[_newAddress], "New address exists");
        require(_newAddress != address(0), "No 0x0 address");

        address[] memory approvedTokens = tokenWhiteList.getApprovedTokens();
        // loop through funds to re-assign balances
        for (uint256 i = 0; i < approvedTokens.length; ) {
            Balance memory oldAddressBalance = tokenBalance[_msgSender()][
                approvedTokens[i]
            ];

            Treasury storage treasury = tokenTreasury[approvedTokens[i]];
            address[] storage workerArray = treasury.workersWithStream;
            // replace old address with new address in array
            if (oldAddressBalance.streamIndex != 0) {
                workerArray[oldAddressBalance.streamIndex] = _newAddress;
            }

            // delete old balance mapping to protect against re-entrancy
            delete (tokenBalance[_msgSender()][approvedTokens[i]]);
            tokenBalance[_newAddress][approvedTokens[i]] = oldAddressBalance;
            unchecked {
                i++;
            }
        }

        delete (workers[_msgSender()]);
        workers[_newAddress] = true;

        emit WorkerAddressUpdated(_msgSender(), _newAddress);
    }

    /** ============== PAYROLL FUNCTIONS =================== **/

    /** @notice
        Bulk executes payroll by updating the amount of funds that workers
        can claim from the contract. Accepts ordered arrays, must be smaller
        than length 500 to protect function from dynamic array loop */
    /** @dev
        The input arrays must be aligned such that if worker A is owed 15
        USDC:
        _workerAddresses[0] = worker A address
        _tokenAddresses[0] = USDC
        _amounts[0] = 15 */
    /// @param _workerAddresses The array of workers being paid
    /// @param _tokenAddresses The array of tokens corresponding to payments
    /// @param _amounts The array of amounts corresponding to payments
    function bulkPayWorkers(
        address[] calldata _workerAddresses,
        address[] calldata _tokenAddresses,
        uint256[] calldata _amounts
    ) external whenNotPaused onlyAdminOrOwner {
        require(_workerAddresses.length <= 500, "Batch max size is 500");
        require(
            _workerAddresses.length == _tokenAddresses.length &&
                _workerAddresses.length == _amounts.length,
            "Array lengths inequal"
        );

        for (uint256 i = 0; i < _workerAddresses.length; ) {
            require(workers[_workerAddresses[i]], "Worker doesnt exist");
            require(_amounts[i] > 0, "Must be non-zero");
            require(
                tokenWhiteList.isApprovedToken(_tokenAddresses[i]),
                "Token unapproved"
            );
            require(
                tokenTreasury[_tokenAddresses[i]].staticBalance >= _amounts[i],
                "Insufficient funds"
            );

            // decrement treasury owned funds
            tokenTreasury[_tokenAddresses[i]].staticBalance -= _amounts[i];

            // send funds directly
            IERC20Upgradeable(_tokenAddresses[i]).safeTransfer(
                _workerAddresses[i],
                _amounts[i]
            );
            unchecked {
                i++;
            }
        }

        emit WorkersBulkPaid(_workerAddresses, _tokenAddresses, _amounts);
    }

    /// @notice Sends funds directly from the treasury to the worker's wallet
    /// @param _amount The amount to send to the worker
    /// @param _token The address of the token being sent
    /// @param _worker The address of the worker's wallet to send funds to
    function directTransfer(
        uint256 _amount,
        address _token,
        address _worker
    )
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_amount <= getStaticTreasury(_token), "Insufficient funds");
        require(_amount > 0, "Must be non-zero");

        // Decrement treasury accounting before sending funds
        tokenTreasury[_token].staticBalance -= _amount;

        emit DirectTransfer(_amount, _worker, _token);

        IERC20Upgradeable(_token).safeTransfer(_worker, _amount);
    }

    /// @notice Increments the account of the user's settled funds
    /// @param _amount The amount to add to the worker's balance
    /// @param _token The address of the token being sent
    /// @param _worker The address of the worker
    function transferToWorkerBalance(
        uint256 _amount,
        address _token,
        address _worker
    )
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_amount != 0, "Must be non-zero");

        // Decrement funds from treasuries nonStreaming funds
        tokenTreasury[_token].staticBalance -= _amount;

        // Add funds to user's balance in the contracts
        Balance storage b = tokenBalance[_worker][_token];
        b.settled += _amount;

        emit TransferToWorkerBalance(_amount, _worker, _token);
    }

    /* ============= STREAMING PAYROLL FUNCTIONS =============== */

    /// @notice Creates a new payroll stream
    /// @param _worker The address of the worker receiving the stream
    /// @param _token The address of the token being streamed
    /// @param _start When the stream begins (in seconds past the epoch)
    /// @param _end When the stream ends (in seconds past the epoch)
    /// @param _rate The rate at which the stream is paying the worker
    function createStream(
        address _worker,
        address _token,
        uint256 _start,
        uint256 _end,
        uint256 _rate
    )
        public
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_start < _end, "start > end");
        require(_rate > 0, "rate == 0");
        require(_start > block.timestamp, "Start cant be in past");

        Balance storage b = tokenBalance[_worker][_token];
        Treasury storage t = tokenTreasury[_token];

        require(b.current.rate == 0, "Stream already created");
        require(t.workersWithStream.length < 500, "Max streams reached");

        if (t.workersWithStream.length == 0) {
            // if this is the first stream created, capture the 0 spot to prevent
            // a worker from having an index of 0
            t.workersWithStream.push(address(0x0));
        }

        // add worker to treasury.workersWithStream array if not already present
        if (b.streamIndex == 0) {
            b.streamIndex = t.workersWithStream.length;
            t.workersWithStream.push(_worker);
        }

        Stream memory newStream = Stream({
            start: _start,
            end: _end,
            withdrawn: 0,
            rate: _rate
        });

        b.current = newStream;

        emit StreamCreated(_worker, _token, _start, _end, _rate);
    }

    /// @notice Creates a new payroll stream
    /// @param _workerAddresses The addresses of the workers receiving the stream
    /// @param _tokenAddresses The addresses of the tokens being streamed
    /// @param _startTimes When the streams begins (in seconds past the epoch)
    /// @param _endTimes When the streams ends (in seconds past the epoch)
    /// @param _rates The rate at which the stream is paying the worker
    function bulkCreateStreams(
        address[] calldata _workerAddresses,
        address[] calldata _tokenAddresses,
        uint256[] calldata _startTimes,
        uint256[] calldata _endTimes,
        uint256[] calldata _rates
    ) external whenNotPaused onlyAdminOrOwner {
        require(_workerAddresses.length <= 100, "Bulk max size is 100");
        require(
            _workerAddresses.length == _tokenAddresses.length &&
                _workerAddresses.length == _startTimes.length &&
                _workerAddresses.length == _endTimes.length &&
                _workerAddresses.length == _rates.length,
            "Arrays must be equal length"
        );

        for (uint256 i = 0; i < _workerAddresses.length; ) {
            createStream(
                _workerAddresses[i],
                _tokenAddresses[i],
                _startTimes[i],
                _endTimes[i],
                _rates[i]
            );
            unchecked {
                i++;
            }
        }
    }

    /// @notice Edits an existing payroll stream
    /// @param _worker The address of the worker receiving the stream
    /// @param _token The address of the token being streamed
    /// @param _start When the stream begins (in seconds past the epoch)
    /// @param _end When the stream ends (in seconds past the epoch)
    /// @param _rate The rate at which the stream is paying the worker
    function editStream(
        address _worker,
        address _token,
        uint256 _start,
        uint256 _end,
        uint256 _rate
    )
        external
        onlyAdminOrOwner
        whenNotPaused
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_start < _end, "start > end");
        require(_rate > 0, "rate==0 ");
        require(_start > block.timestamp, "Start cant be in the past");

        Balance storage b = tokenBalance[_worker][_token];
        require(b.current.start != 0, "No stream exists");
        Stream memory newStream = Stream({
            start: _start,
            end: _end,
            withdrawn: 0,
            rate: _rate
        });

        if (b.next.rate != 0) {
            /* Update balance object before editing. If the current stream has
            ended, the struct needs to be updated so that the next stream is
            swapped into the current stream location. */
            _updateBalance(_worker, _token);
        }

        if (_start < b.current.start) {
            b.current = newStream;
            if (_end > b.next.start) {
                b.next.start = _end;
            }
            return ();
        }

        // can not have 2 streams exist at the same time.
        if (b.current.end >= _start) {
            b.current.end = _start; //current stream ends when new stream starts
        }

        b.next = newStream;

        _updateBalance(_worker, _token);

        emit StreamEdited(_worker, _token, _start, _end, _rate);
    }

    /// @notice terminates the active payroll stream at specified time
    /// @param _worker The address of the worker receiving the stream
    /// @param _token The address of the token being streamed
    /// @param _end When the stream ends (in seconds past the epoch)
    function endStream(
        address _worker,
        address _token,
        uint256 _end
    )
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_end > block.timestamp, "End time in past");

        Balance storage b = tokenBalance[_worker][_token];
        require(b.current.start != 0, "No stream exists");

        // if current stream is ongoing, set its end time
        // if current stream has ended, set end time of next stream if it exists
        if (b.current.end > block.timestamp) {
            require(_end <= b.current.end, "new end > existing end");
            require(_end > b.current.start, "end < start time");
            b.current.end = _end;
        } else if (b.current.end < block.timestamp) {
            require(b.next.start != 0, "No stream exists");
            require(_end <= b.next.end, "new end > existing end");
            require(_end > b.next.start, "end < start");

            b.next.end = _end;
        }

        emit StreamEnded(_worker, _token, _end);
    }

    /*  @notice This function deletes a stream. It returns any unclaimed value
        to the streaming treasury */
    /// @param _worker The worker whos stream is being deleted
    /// @param _token  The token balance in which the stream is being deleted
    function deleteStream(address _worker, address _token)
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        Treasury storage t = tokenTreasury[_token];
        Balance storage b = tokenBalance[_worker][_token];
        require(b.current.start != 0 || b.next.start != 0, "No stream exists");

        // if current stream hasn't ended, delete current stream
        if (block.timestamp < b.current.end) {
            t.settledStreamingBalance -= b.current.withdrawn;
            b.current = b.next;
            delete (b.next);
            // if current stream has ended, delete next stream
        } else if (b.current.end < block.timestamp) {
            t.settledStreamingBalance -= b.next.withdrawn + b.current.withdrawn;
            delete (b.current);
            delete (b.next);
        }

        emit StreamDeleted(_worker, _token);
    }

    /** @notice Updates the Balance struct. If the stream in the balance.current
        position has expired, the stream in balance.new will move to the
        balance.current position. This ensures that, as streams are edited,
        no stream currently streaming is overridden */
    /// @param _worker The address of the worker associated with the stream
    /// @param _token The address of the token in the stream
    function _updateBalance(address _worker, address _token) internal {
        Balance storage b = tokenBalance[_worker][_token];
        Treasury storage t = tokenTreasury[_token];
        // Check current stream has expired and that it exists
        if (b.current.end <= block.timestamp && b.current.end != 0) {
            // sweep funds from expired stream to the users settled balance
            b.settled += _getCurrentStreamBalance(_worker, _token);
            // subtract settled stream amount from the settled streaming balance
            t.settledStreamingBalance -=
                (b.current.end - b.current.start) *
                b.current.rate;

            b.current = b.next;
            // delete new stream so slot is empty
            delete (b.next);
        }
    }

    /** @notice Allows workers to claim their funds. Funds are pulled from the
        settled funds before pulling from stream balances */
    /// @param _amount The amount to be claimed by the worker
    /// @param _token The token being claimed by the worker
    function claimPayroll(uint256 _amount, address _token)
        external
        whenNotPaused
        onlyWorker
    {
        require(_amount > 0, "amount==0");

        // ensure that balance object is current before a user claims
        _updateBalance(_msgSender(), _token);

        Balance storage b = tokenBalance[_msgSender()][_token];
        uint256 totalBalance = b.settled +
            getStreamBalance(_msgSender(), _token);

        require(_amount <= totalBalance, "Insufficient balance");

        if (_amount <= b.settled) {
            b.settled -= _amount;

            emit PayrollClaimed(_msgSender(), _amount, _token);
            IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
        } else {
            uint256 amountDue = _amount;
            amountDue -= b.settled;
            b.settled = 0;
            // account for funds withdrawn from stream
            /* because Balance object is updated at start of function, the
            balance.current object will always be the active stream */
            b.current.withdrawn += amountDue;

            emit PayrollClaimed(_msgSender(), _amount, _token);
            IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
        }
    }

    /* ============== Treasury Management =========== */

    /// @notice Deposit funds to the non-streaming treasury (static treasury)
    /// @param _amount The amount of funds to be deposited
    /// @param _token The token to be deposited
    function depositStaticFunds(uint256 _amount, address _token)
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
    {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 allowance = token.allowance(_msgSender(), address(this));

        require(_amount > 0, "amount==0");
        require(allowance >= _amount, "Insufficient allowance approved");

        Treasury storage t = tokenTreasury[_token];
        t.staticBalance += _amount;

        emit StaticDeposit(_amount, _token);
        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /// @notice Deposit funds to the streaming treasury
    /// @param _amount The amount of funds to be deposited
    /// @param _token The token to be deposited
    function depositStreamingFunds(uint256 _amount, address _token)
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
    {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 allowance = token.allowance(_msgSender(), address(this));

        require(_amount > 0, "amount==0");
        require(allowance >= _amount, "Insufficient allowance");

        Treasury storage treasury = tokenTreasury[_token];
        treasury.settledStreamingBalance += _amount;

        emit StreamingDeposit(_amount, _token);
        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /// @notice Withdraw funds from the static treasury
    /// @param _token The token to withdraw
    /// @param _amount The amount being withdrawn from the treasury
    function withdrawStaticFunds(address _token, uint256 _amount)
        external
        whenNotPaused
        onlyAdminOrOwner
    {
        require(_amount != 0, "amount==0");

        uint256 staticBalance = getStaticTreasury(_token);

        require(_amount <= staticBalance, "Insufficient funds");

        Treasury storage treasury = tokenTreasury[_token];
        treasury.staticBalance -= _amount;

        emit StaticWithdrawal(_amount, _token);
        IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
    }

    /// @notice This function withdraws funds from the Streaming Treasury only
    /// @param _token The token treasury from which funds are being withdrawn
    /// @param _amount The amount to be withdrawn from the treasury
    function withdrawStreamingFunds(address _token, uint256 _amount)
        external
        whenNotPaused
        onlyAdminOrOwner
    {
        require(_amount != 0, "amount==0");
        uint256 streamingBalance = getStreamingTreasury(_token);

        require(_amount <= streamingBalance, "Insufficient funds");

        Treasury storage treasury = tokenTreasury[_token];
        treasury.settledStreamingBalance -= _amount;

        emit StreamingWithdrawal(_amount, _token);
        IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
    }

    /*** Contract Operations ***/

    // @notice Pause the smart contract
    function pause() external onlyOwner {
        _pause();
    }

    // @notice UnPause the contract. Ensure contract is in a secure state
    function unpause() external onlyOwner {
        _unpause();
    }

    /** MsgSender() inheritance resolution **/
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "draft-IERC20PermitUpgradeable.sol";
import "AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "draft-IERC1822Upgradeable.sol";
import "ERC1967UpgradeUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "IBeaconUpgradeable.sol";
import "draft-IERC1822Upgradeable.sol";
import "AddressUpgradeable.sol";
import "StorageSlotUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is
    Initializable,
    ContextUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    function __ERC2771Context_init(address trustedForwarder)
        internal
        onlyInitializing
    {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// contracts/Franklin.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "Ownable.sol";

contract FranklinTokenWhitelist is Ownable {
    /// ============ EVENTS ============
    /// @notice Emits address of the ERC20 token approved
    event TokenApproved(address _token);
    /// @notice Emits address of the ERC20 token removed
    event TokenRemoved(address _token);

    /// ============ STORAGE VARIABLES ============

    /** @dev
      The approvedTokens array and registeredToken mapping are used to manage
      the tokens approved for payroll. This is used to ensure that tokens in
      the treasury which are not allocated to Payroll are not accidentally
      used in a payroll run */
    address[] private approvedTokens;

    /// @dev Mapping manages registerdTokens and indicates if a _token is registered
    mapping(address => bool) private registeredToken;

    constructor(address[] memory initially_approved_tokens) {
        for (uint256 i = 0; i < initially_approved_tokens.length; ) {
            addApprovedToken(initially_approved_tokens[i]);
            unchecked {
                i++;
            }
        }
    }

    /// Protect owner by overriding renounceOwnership
    function renounceOwnership() public virtual override {
        revert("Cant renounce");
    }

    /// ============ MODIFIERS ============

    modifier onlyApprovedTokens(address _token) {
        require(registeredToken[_token], "Token not approved");
        _;
    }

    /// ============ VIEW FUNCTIONS ============

    function getApprovedTokens() external view returns (address[] memory) {
        return (approvedTokens);
    }

    function isApprovedToken(address _token) external view returns (bool) {
        return (registeredToken[_token]);
    }

    /// ============ TOKEN MANAGEMENT FUNCTIONS ============

    /** @notice
      Adds the ERC20 token address to the registeredToken array and creates a
      mapping that returns a boolean showing the token is approved. */
    /// @dev This function is public because it is called by the initializer
    /// @param _token The ERC20 token to be approved
    function addApprovedToken(address _token) public onlyOwner {
        require(!registeredToken[_token], "Token already approved");
        require(_token != address(0), "No 0x0 address");

        registeredToken[_token] = true;
        approvedTokens.push(_token);

        emit TokenApproved(_token);
    }

    /** @notice
      Removes the ERC20 token from the registeredToken array and
      deletes the mapping used to confirm a token is approved */
    /// @param _token The ERC20 token to be removed
    function removeApprovedToken(address _token)
        external
        onlyOwner
        onlyApprovedTokens(_token)
    {
        // set mapping to false
        registeredToken[_token] = false;

        // remove from approved token array
        for (uint256 i = 0; i < approvedTokens.length; ) {
            if (approvedTokens[i] == _token) {
                // replace deleted _token with last _token in array
                approvedTokens[i] = approvedTokens[approvedTokens.length - 1];
                // remove last spot in array
                approvedTokens.pop();
                break;
            }
            unchecked {
                i++;
            }
        }

        emit TokenRemoved(_token);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// contracts/Franklin.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IFranklinTokenWhitelist {
    function getApprovedTokens() external view returns (address[] memory);

    function isApprovedToken(address _token) external view returns (bool);

    /// ============ TOKEN MANAGEMENT FUNCTIONS ============

    /** @notice
      Adds the ERC20 token address to the registeredToken array and creates a
      mapping that returns a boolean showing the token is approved. */
    /// @dev This function is public because it is called by the initializer
    /// @param _token The ERC20 token to be approved
    function addApprovedToken(address _token) external;

    /** @notice
      Removes the ERC20 token from the registeredToken array and
      deletes the mapping used to confirm a token is approved */
    /// @param _token The ERC20 token to be removed
    function removeApprovedToken(address _token) external;
}
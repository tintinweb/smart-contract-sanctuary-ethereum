//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @title EntroBeam ver 1.0.1
/// @author Leon Wesker, [email protected], [email protected]
///
/// @notice This contract provides secure entropy in an unpredictable and unbiased.
/// User's Entropy transactions(EntropyRegister) are aggregate as much as the value of the 'FormationNumber' variable. 
/// Then, mix the value of the median gas fee with the value of the minimum/max average of the gas fee to select one. 
/// And it combines it with the EntropyRegister transaction that occurred after the 'upcomingRevealBlockNo' +1 block.
/// The initial value of 'FormationNumber' is 10, 'upcomingRevealBlockNo' is 0 and it will increase gradually.
/// Entropy can also be applied immediately to random bit generators(RGBs, random number generators, RNGs) and is essential
/// for statistics and probability distributions.
///
/// @dev The basic way to use this contract is to send a transaction to an arbitrary 256bit hex string Entropy Seeds including
/// 0x to the 'EntropyByUsers' function; it is stored in 'struct_EntropyRegister'. And when revealed(When mixed with the entropy
/// seed of other users with the Entropy Chain, it is called reveal(settle). The token reward will be sent at this time.),
/// Contract's entropy will registered in 'struct_EntropyRegister.revealEntropy'. EntroBeam Token is calculated and distributed
/// by Epoch (Unix timestamp). Token allocation is divided according to the number of users per block. Since it is calculated as
/// an epoch, token distribution is reduced regardless of the number of users participating. As an upgradeable ERC20, EntroBeam will
/// upgrade sequentially.

/// @dev upgradeable ERC20 Token
import "ERC20Upgradeable.sol";
import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "UUPSUpgradeable.sol";

/// @dev PRB Math
import "PRBMathSD59x18.sol";
import "PRBMathSD59x18Typed.sol";
import "PRBMathUD60x18.sol";
import "PRBMathUD60x18Typed.sol";

contract EEEtest is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    ///@notice initialize is upgradeable_ERC20 constroctor
    function initialize() public initializer {
        ///upgradeable_ERC20 zeppelin lines start
        __ERC20_init("EEEtest", "EEE");
        __Ownable_init();
        __UUPSUpgradeable_init(); //solves duplicate values in the solidity storage while upgrading.
        _mint(msg.sender, 1000000000 * 10**decimals());
        ///upgradeable_ERC20 zeppelin lines end

//        test_account = payable(msg.sender); /////TEST. This code exists only in TEST-NET.

        ///Initializes 0 in the users Entropy array and matches numberLatestUsersEntropy.
        Array_EntropyChain.push(
            struct_EntropyChain(
                0x0000000000000000000000000000000000000000000000000000000000000001,
                0,
                0x0000000000000000000000000000000000000000,
                0
            )
        );

        RecentRevealEntropyNumber = 1;
        creationEpoch = block.timestamp;
        AllocationInterval = 13;
        upcomingRevealBlockNo = 0;
        InitToken = 30000000 * 10**decimals();

        //This value gradually increases as the number of contract participants increases.
        FormationNumber = 10;
    }

    /// @notice even if the contract is upgrade, the user does not need to do any actions such as change the contract address
    /// or swap tokens. The user can trust that all calls to the previous version contract will be delegated to the latest logic
    /// contract’s implementation of the latest version contract.
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @dev enable PRBMathSD59x18
    using PRBMathSD59x18Typed for uint256;
    using PRBMathSD59x18Typed for uint8;
    using PRBMathSD59x18Typed for uint256;
    using PRBMathSD59x18 for uint256;
    using PRBMathSD59x18 for uint8;
    using PRBMathSD59x18 for uint256;

    /// @dev enable PRBMathUD60x18
    using PRBMathUD60x18Typed for uint256;
    using PRBMathUD60x18Typed for uint8;
    using PRBMathUD60x18Typed for uint256;
    using PRBMathUD60x18 for uint256;
    using PRBMathUD60x18 for uint8;
    using PRBMathUD60x18 for uint256;

    /// @dev Contract Create Unix-time. use to calculate the token distribution amount.
    uint256 public creationEpoch;

    /// @dev total number of entropy sent by the user. Matches the array number in 'Array_EntropyChain'
    uint256 public numberLatestUsersEntropy;

    /// @dev The actual user number be -1 from this variable. A sequence number that has not been settled(revealed) yet.
    /// The value drawn from 'Assigned_EntropyChain' is combined with 'RecentRevealEntropyNumber - 1' to become contract reveal entropy.
    uint256 public RecentRevealEntropyNumber;

    /// @dev Block Target Time. It is an integer-type unit of seconds, and when the Block Target Time of the Network is changed,
    /// this value will also change. refer to 'rewardsPerBlock()'
    uint256 public AllocationInterval;

    /// @dev Annual token supply. It is calculated based on the epoch, it is a very close approximation.
    /// Supply continues to decrease each year. refer to 'rewardsPerBlock()'
    uint256 public InitToken;
    
    /// @dev InitToken has already been assigned to 30000000 in function initialize().
    /// Nevertheless, changes may be made in the future if there is a compelling reason to do so.
    function setInitToken(uint256 _InitToken) external payable onlyOwner noReentrancy {
        InitToken = _InitToken;
    }

    /// @notice modifier that prevent re-entrancy attacks
    bool private locked;
    modifier noReentrancy() {
        require(!locked, "Not allow re-entrancy, Try Agin"); // init locked must be false
        assert(!locked);
        locked = true;
        _;
        locked = false;
    }

    //// @notice TEST. This code exists only in TEST-NET.
    ////
    //// Caveats:
    //// - In Binance Main Network, this function does not exist.
    address payable test_account;
    //// @notice TEST. This function exists only in TEST-NET.
    function DisbandToken() external payable onlyOwner noReentrancy {
        selfdestruct(test_account);
    }

    event F_receive(uint8, address, uint256, bytes4); // event recevice function.
    event F_fallback(address, uint256); // event fallback function.

    fallback() external payable noReentrancy {
        emit F_fallback(msg.sender, msg.value);
    }

    receive() external payable noReentrancy {
        emit F_receive(42, msg.sender, msg.value, msg.sig);
    }

    /// @notice users entropy register(like DB)
    /// stored and called the entropy value(arbitrary 256bit hex string Entropy including 0x) sent by the users
    ///
    /// @dev 'revealEntropy' always returns 0x00000000000000000000000000000000000000000000000000000000000000000000 in the
    /// unsettled state. Reveals are not processed all at once but sequentially one by one.
    /// Reveals are not processed at once but are processed one by one sequentially when Tx after 'FormationNumber' occurs.
    struct struct_EntropyRegister {
        bytes32 usersEntropy; //end-user entropy seed
        bool verifyDuplicate; //check duplicate entropy seeds true=duplicate, false=non-duplicate
        bytes32 revealEntropy; //Entropy generated by the Contract and sent to the user
    }

    /// @notice check the number of tx in an account address
    /// stored and called the user account address
    ///
    /// @dev ready for the next version.
    struct struct_accountTxCount {
        address accountAddress;
        uint256 A_counting;
    }

    /// @notice will be defined as an array utilized in chain systems that shuffle the seeds to generate entropy with reliability.
    struct struct_EntropyChain {
        bytes32 entropyByUsers; //end-user entropy seed
        uint256 entropyByBlockNumber; //Seed block.number. Interacts with 'struct_blockCount' and is used to divide the token quota per block.
        address SourceAddress; //address of the user who sent the seed.
        uint256 leftgas; //Each gas fee to Tx is applied to calculate the median and average values of the entropy chain.
    }

    /// @notice Entobeam Token (RGB) calculates the annual issuance based on the epoch(Unix-timestamp) and then estimates
    /// the distribution per block. If only one user-submitted Entropy in the one block, one user will receive all tokens
    /// allocated in the one block, but that token amount will be divided if there are multiple users.
    /// This struct stores the number of EntropyRegister occurrences in the block.
    struct struct_blockCount {
        uint256 blockCount;
    }

    /// @notice 'struct_EntropyChain' is used not mapping, used only as an array, and forms a chain with the
    /// median and average of the gas fee. Array_EntropyChain sequentially assigns numbers to transactions that have successfully
    /// executed EntropyRegister. Number 1 is assigned to the Tx that first generated Tx since the contract was created.
    /// And it is sequentially increase 2,3,4....
    ///
    /// 'numberLatestUsersEntropy' == 'Array_EntropyChain'
    struct_EntropyChain[] public Array_EntropyChain;

    mapping(bytes32 => struct_EntropyRegister) public struct_EntropyRegister_ID;
    mapping(address => struct_accountTxCount) public struct_accountTxCount_ID;
    mapping(uint256 => struct_blockCount) public struct_block_ID;

    /// @dev gas fee array of 'Assigned_EntropyChain' set as 'FormationNumber'.
    uint256[] Array_toBeMedian;

    /// @dev Select and push the ones that become FormationNumber in Array_EntropyChain. The settle(reveal) number is immediately
    /// move and delete by pop. The value drawn from 'Assigned_EntropyChain' is combined with 'RecentRevealEntropyNumber - 1'
    /// to become contractEntropy.
    uint256[] public Assigned_EntropyChain;

    /// @dev When 'Assigned_EntropyChain_length' and 'FormationNumber' are the same and Tx of 'EntroRegister' becomes +1, the
    /// average and median values are calculated, and entropy is drawn lots from 'EntroRegister' and mixed with the entropy of
    /// 'RecentRevealEntropyNumber'. The EntropyRegister that started these processes is not included in the Entropychain. In other words,
    /// the latest transaction that generated entropy seed cannot be combined with EntropyRegister.
    /// When the Entropy of the Contract is Revealed, the 'FormationNumber' element is deleted, and the 'Assigned_EntropyChain' element
    /// is added, so the two values always match.
    /// However, if the contract has just been created or the value of 'FormationNumber' increases, revealEntropy will not occur until
    /// 'FormationNumber' is filled.
    /// So 'Assigned_EntropyChain_length' is useful when comparing length with 'FormationNumber'.
    uint256 public Assigned_EntropyChain_length =
        Assigned_EntropyChain.length;

    /// @dev The number of elements of 'Assigned_EntropyChain.length'. This value is only increased and only
    /// even numbers are allowed to improve the reliability of the median.
    /// The reveal process is generate at 'FormationNumber +1'.
    ///
    /// EntroChain's Reveal process works at +1 Block even if the 'FormationNumber' is full. Therefore, even if an 
    /// EntroRegister transaction exceeding 'FormationNumber' occurs in one block, the Reveal process does not work because 
    /// it is not +1 Block. In this case, 'Assigned_EntropyChain' is exceeded, but this is the intended process.
    /// It's completely normal.
    uint256 public FormationNumber;
    
    /// @notice The entropy seed sent by the user is transmitted to EntroBeam and stored in the Entropy register.
    /// Even a small noise in the gas fee will affect the median and average values of the entropy chain.
    /// - Data and gas fee of each transaction is aggregate as much as 'FormationNumber'. Therefore, as the value of
    ///  'FormationNumber' increases, entropy reliability increase proportionally.
    ///
    /// @param _usersHexData 256bits hexadecimal string specified by the user. duplicate values are reverted.
    ///
    /// @dev can be inherited and used, and when the reveal is completed, the token is transfer to the user, and at the
    /// same time, the reveal entropy is stored in 'struct_EntropyRegister.revealEntropy'.
    ///
    /// Caveats:
    /// - Depending on the state of the network, the number of contract participants, and the internal state of the contract,
    ///   the gas fee required varies each time.
    /// - If multiple Tx are generate with the same gas fee, transaction is revert to out of gas.
    ///
    /// Requirements:
    /// - The same '_usersHexData' (Entropy seed) will be reverted.
    function EntropyByUsers(bytes32 _usersHexData) public noReentrancy {
        struct_blockCount storage scheme_blockCount = struct_block_ID[
            block.number
        ];
        scheme_blockCount.blockCount++;

        uint256 _gas = gasleft();

        struct_EntropyRegister
            storage scheme_EntropyRegister = struct_EntropyRegister_ID[
                _usersHexData
            ];

        if (scheme_EntropyRegister.verifyDuplicate == true) {
            revert("Duplicate Seeds Data");
        } else {
            scheme_EntropyRegister.usersEntropy = _usersHexData;
            scheme_EntropyRegister.verifyDuplicate = register_InToChain(
                scheme_EntropyRegister.usersEntropy,
                block.number,
                _gas
            );
            numberLatestUsersEntropy++;
        }

        struct_accountTxCount
            storage scheme_accountTxCount = struct_accountTxCount_ID[msg.sender];

        if (scheme_accountTxCount.accountAddress != address(0)) {} else {
            scheme_accountTxCount.accountAddress = msg.sender;
        }
        scheme_accountTxCount.A_counting++;

        // Except for the already settled(revealed) user entropy Tx, it stores up to 'numberLatestUsersEntropy'-1 in the array.
        // The reason for applying only -1 is to prevent the latest EntropyRegister Tx from being used as the entropy seed or noise.
        for (uint256 i = 0; i < Assigned_EntropyChain.length; i++) {
            Array_toBeMedian.push() = Array_EntropyChain[
                Assigned_EntropyChain[i]
            ].leftgas;
        }

        mathMedian(Array_toBeMedian, Array_toBeMedian.length);
        delete Array_toBeMedian;

        // After processes are finished, push the current being transaction data in 'Assigned_EntropyChain'.
        // The current user will receive the entropy seed of the subsequent processes.
        Assigned_EntropyChain.push(numberLatestUsersEntropy);
        Assigned_EntropyChain_length = Assigned_EntropyChain.length;
    }

    /// @notice Change the value of 'FormationNumber'. This value is only incremented
    /// @param _a Specify an integer
    function set_FormationNumber(uint256 _a) external onlyOwner noReentrancy {
        require(
            _a > FormationNumber && _a % 2 == 0,
            "FormationNumber cannot be reduced or odd number"
        );
        FormationNumber = _a;
    }

    /// @notice Push the data from EntropyRegister to the EntropyChain array.
    ///
    /// @param _hex struct_EntropyRegister.usersEntropy
    /// @param _blockNumber current block.number
    /// @param _gas_ gasleft()
    /// @return struct_EntropyRegister.verifyDuplicate == true
    function register_InToChain(
        bytes32 _hex,
        uint256 _blockNumber,
        uint256 _gas_ /*, bytes4 _msgSig*/
    ) private returns (bool) {
        Array_EntropyChain.push(
            struct_EntropyChain(_hex, _blockNumber, msg.sender, _gas_)
        );
        return true;
    }

    /// @notice same as struct_EntropyRegister.revealEntropy
    /// @dev Confusion arises when many events are logged in one Tx. Each event is recorded only once per transaction.
    /// This is why Contracts does not reveal EntropyChain all at once.
    event Contract_Reveal_Entropy(bytes32);

    /// @notice Token transfer only call with EntropyChain
    ///
    /// @dev The reward token per block is divided by the number of users who made a transaction in
    ///'EntropyRegister' per block target time('AllocationInterval'). Tokens are distributed after calculating to
    /// 18 decimal points. _transferToken_() is closely related to rewardsPerBlock()
    ///
    /// @param _from this contract address
    /// @param _to 'RecentRevealEntropyNumber' user address
    /// @param _currentContract_Entropy 'struct_EntropyRegister.revealEntropy'
    /// @param _blockNumber Divide the allocated tokens per block by the number of 'struct_blockCount.blockCount'
    /// @return Not applicable yet
    function _transferToken_(
        address _from,
        address _to,
        bytes32 _currentContract_Entropy,
        uint256 _blockNumber
    ) private returns (bool) {
        struct_blockCount storage scheme_blockCount = struct_block_ID[
            _blockNumber
        ];

        _transfer(
            _from,
            _to,
            PRBMathUD60x18.div(
                rewardsPerBlock(),
                PRBMathUD60x18.fromUint(scheme_blockCount.blockCount)
            )
        );
        emit Contract_Reveal_Entropy(_currentContract_Entropy);
        return true;
    }

    /// @dev It records which users' entropy is mixed as a seed to generate reliable entropy.
    /// The actual number in '_RecentRevealEntropyNumber_' should apply -1.
    /// The numeral of '_moduloAssigned_EntropyChain_' is the numeral of elements in the Array_EntropyChain array.
    event Assigned_EntropyChain_number(
        uint256 _moduloAssigned_EntropyChain_,
        uint256 _RecentRevealEntropyNumber_
    );

    /// @dev modulo values used in EntropyChain are used in the probability distribution model to be upgraded to Phase2
    /// together with Register/Chain. If the modulo values do not fit into the probability distribution, Phase2 will not
    /// use the modulo
    uint256[] public medianAvg_mod;

    /// @dev array for checking the probability distribution model.
    uint256[] public minMaxAvr;

    /// @dev Even if 'FormationNumber' is filled, Reveal occurs only when a transaction occurs in a future block that is 
    /// ahead of the block number of the Entropy Register to be Revealed by 'upcomingRevealBlockNo' + 1 blockNumber.
    uint256 public upcomingRevealBlockNo;

    /// @notice As 'upcomingRevealBlockNo' increases along with 'FormationNumber', the unpredictability of the entropy 
    /// chain increases.
    ///
    /// @param _upcomingRevealBlockNo New upcomingRevealBlockNo Number
    function SetUpcomingRevealBlockNo(uint256 _upcomingRevealBlockNo)
        external
        onlyOwner
        noReentrancy
    {
        upcomingRevealBlockNo = _upcomingRevealBlockNo;
    }

    /// @notice When a user's entropy seed comes from a block number greater than upcomingRevealBlockNo + 1 && 'FormationNumber' 
    /// is filled combined with the user's entropyRegister that has not yet been returned('RecentRevealEntropyNumber'), and the
    /// contract revealEntropy and Token are sent to the 'RecentRevealEntropyNumber'.
    ///
    /// @dev If 'FormationNumber' is filled once and there is no change, and if there is an inbound Tx in
    /// 'struct_EntropyRegister', 'RecentRevealEntropyNumber' will always reveal contract entropy.
    ///
    /// @param _median median value of 'Array_toBeMedian'
    /// @return Not applicable yet
    function combinEntropyMedian(uint256 _median) private returns (bytes32) {
        bytes32 _hashCH;
        
        // 
        if (
            block.number >
            Array_EntropyChain[RecentRevealEntropyNumber]
                .entropyByBlockNumber + upcomingRevealBlockNo &&
            Assigned_EntropyChain.length >= FormationNumber
        ) {
            uint256 _minMaxAvr = PRBMathUD60x18.avg(
                Array_EntropyChain[Assigned_EntropyChain[0]].leftgas,
                Array_EntropyChain[
                    Assigned_EntropyChain[
                        Assigned_EntropyChain.length - 1
                    ]
                ].leftgas
            );
            minMaxAvr.push(_minMaxAvr);
            uint256 _modulo = ((_median % (FormationNumber - 1)) +
                (_minMaxAvr % (FormationNumber - 1))) % (FormationNumber - 1);

            // gasleft(), msg.data may be applied as Noise later.
            _hashCH = keccak256(
                abi.encode(
                    Array_EntropyChain[Assigned_EntropyChain[_modulo]]
                        .entropyByUsers,
                    Array_EntropyChain[RecentRevealEntropyNumber].entropyByUsers /*, gasleft(), msg.data*/
                    //
                )
            );
            emit Assigned_EntropyChain_number(
                Assigned_EntropyChain[_modulo],
                RecentRevealEntropyNumber
            );

            medianAvg_mod.push() = _modulo;

            _transferToken_(
                address(this),
                Array_EntropyChain[RecentRevealEntropyNumber].SourceAddress,
                _hashCH,
                Array_EntropyChain[RecentRevealEntropyNumber]
                    .entropyByBlockNumber
            );

            struct_EntropyRegister
                storage scheme_EntropyRegister = struct_EntropyRegister_ID[
                    Array_EntropyChain[RecentRevealEntropyNumber].entropyByUsers
                ];
            scheme_EntropyRegister.revealEntropy = _hashCH;

            RecentRevealEntropyNumber++;

            // Elements that have been settled in 'Assigned_EntropyChain' are deleted, and new elements are added.
            // At this point, the array is left shuffled.
            uint256 temp = Assigned_EntropyChain[
                Assigned_EntropyChain.length - 1
            ];
            Assigned_EntropyChain[
                Assigned_EntropyChain.length - 1
            ] = Assigned_EntropyChain[_modulo];
            Assigned_EntropyChain[_modulo] = temp;
            Assigned_EntropyChain.pop();
        }
        return _hashCH;
    }

    /// @dev Separate function to check keccack256
    function keccak256Test(bytes32 _a, bytes32 _b) public pure returns (bytes32) {
        return keccak256(abi.encode(_a, _b));
    }

    /// @notice calculates the median value of an array. Derives the median of all gas ratio components of 'Array_toBeMedian'.
    ///
    /// @param _array 'Array_toBeMedian'
    /// @param _length 'Array_toBeMedian.length'
    /// @return median value
    ///
    /// @dev When the number of arrays is even, the median is calculated based on two elements. However, this contract can be
    /// increased to more than two in future upgrades. That way the median won't be the usual mathematical median, but can be a
    /// better entropy noise.
    function mathMedian(uint256[] memory _array, uint256 _length)
        private
        returns (uint256)
    {
        if (_length == 0) {
            return 0;
        }
        sort(_array, 0, _length);
        uint256 _ak = _length % 2 == 0
            ? get_average(_array[(_length / 2) - 1], _array[_length / 2])
            : _array[_length / 2];
        combinEntropyMedian(_ak);

        return
            _length % 2 == 0
                ? get_average(_array[(_length / 2) - 1], _array[_length / 2])
                : _array[_length / 2];
    }

    /// @dev Swaps the elements of a single array
    ///
    /// @param _i swap with parameter _j
    /// @param _j swap with parameter _i
    function swap(
        uint256[] memory _array,
        uint256 _i,
        uint256 _j
    ) private pure {
        (_array[_i], _array[_j]) = (_array[_j], _array[_i]);
    }

    /// @dev Sort the Array in ascending order
    ///
    /// @param _array array
    /// @param _begin numeral of the first element in the array
    /// @param _end numeral of the last element in the array
    function sort(
        uint256[] memory _array,
        uint256 _begin,
        uint256 _end
    ) private pure {
        if (_begin < _end) {
            uint256 j = _begin;
            uint256 pivot = _array[j];
            for (uint256 i = _begin + 1; i < _end; ++i) {
                if (_array[i] < pivot) {
                    swap(_array, i, ++j);
                }
            }
            swap(_array, _begin, j);
            sort(_array, _begin, j);
            sort(_array, j + 1, _end);
        }
    }

    /// @dev Calculates the average of two integer param
    ///
    /// @param _a first value
    /// @param _b secend value
    function get_average(uint256 _a, uint256 _b)
        private
        pure
        returns (uint256)
    {
        return (_a & _b) + (_a ^ _b) / 2;
    }

    /// @notice Block Chain’s Block Target Time may be change in the future. If the target time is changed, this value must also be changed.
    ///
    /// @param _blockTargerTime average value of block Target Time
    function SetAllocationInterval(uint256 _blockTargerTime)
        external
        onlyOwner
        noReentrancy
    {
        AllocationInterval = _blockTargerTime;
    }

    /// @notice The annual supply is reduced by 0.1% each year in 'InitToken'.
    ///
    /// @dev year = 0 , decline rate = 0 (30,000,000. - (year += 1 * decline rate += 0.1%))
    ///  30,000,000 ->  29,968,464 ->  29,873,856 ->  29,715,917 ->  29,495,078
    /// note that calculations are based on Unix TimeStamp(Epoch) and are approximate.
    ///
    /// @param _x refer to 'rewardsPerBlock()'
    /// @param _y refer to 'rewardsPerBlock()'
    function rewardsPerYear(uint256 _x, uint256 _y)
        private
        view
        returns (uint256)
    {
        return
            InitToken -
            PRBMathUD60x18.mul(
                PRBMathUD60x18.fromUint(_x),
                PRBMathUD60x18.div(
                    PRBMathUD60x18.fromUint(_y),
                    PRBMathUD60x18.fromUint(100)
                )
            );
    }

    /// @notice Calculate token rewards per block.
    /// Divide rewardPerYear() by 3153600 seconds (one year). And multiply that value by Block Target Time.
    /// The Gregorian calendar is 31556952 sec, the Julian year is 31557600 sec, and the leap year is 31622400 sec
    /// This contract sets the reward based on 31536000 seconds per year.
    ///
    /// @dev EntroBeam includes a design to prevent overflow, but please be careful if anyone else devs do anything
    /// with this contract code.If you need to change a formula, you must design it carefully for overflow. Even sometimes,
    /// the process overflows, but the result does not overflow.
    function rewardsPerBlock() public view returns (uint256) {
        uint256 _x = block.timestamp - creationEpoch;
        uint256 _y = PRBMathUD60x18.toUint(
            PRBMathUD60x18.div(
                PRBMathUD60x18.fromUint(_x),
                PRBMathUD60x18.fromUint(31536000)
            )
        );
        return
            PRBMathUD60x18.mul(
                PRBMathUD60x18.div(
                    PRBMathUD60x18.fromUint(rewardsPerYear(_x, _y)),
                    PRBMathUD60x18.fromUint(31536000)
                ),
                AllocationInterval
            );
    }

    /// @notice This contract has no fund distribution function other than the distribution of EntroBeam tokens,
    /// which are rewarded to users who create transactions on EntroBeam's EntroRegister and EntroChain.
    ///
    /// Users do not need and have no reason to transfer funds to this contract under any circumstances. Nevertheless,
    /// if the user sends funds to the contract, the funds are treated as donations. Thus, this function performs the
    /// function of withdrawing donations.
    function DonationWithdraw(address payable _recipient, uint256 _amount)
        external
        onlyOwner
        noReentrancy
    {
        _recipient.transfer(_amount);
    }
}
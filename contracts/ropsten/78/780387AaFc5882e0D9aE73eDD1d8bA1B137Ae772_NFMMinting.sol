/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// LIBRARIES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// SAFEMATH its a Openzeppelin Lib. Check out for more info @ https://docs.openzeppelin.com/contracts/2.x/api/math
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getController() external pure returns (address);

    function _getUV2Pool() external pure returns (address);

    function _getNFMStakingTreasuryERC20() external pure returns (address);

    function _getDaoReserveERC20() external pure returns (address);

    function _getTreasury() external pure returns (address);

    function _getDistribute() external pure returns (address);

    function _getNFM() external pure returns (address);

    function _getTimer() external pure returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IERC20 {
    function _mint(address to, uint256 amount) external;
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMTIMER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmTimer {
    function _getEA()
        external
        pure
        returns (uint256 EYearAmount, uint256 EDayAmount);

    function _getEndMintTime() external pure returns (uint256);

    function _updateDailyMint() external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMMinting.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This contract regulates the minting of the NFM token
/// @dev This contract interacts with 3 interfaces, the timer, the NFM and the controller.
///           ***Minting is performed through a transfer mechanism. hereby, the executor gets a minting bonus of 10 NFM.***
///                                                 ***7.6 billion NFM are created over the course of 8 years***
/// The token amount created will be split as follows:
///     - NFM Staking Pool => 60% of each Minting
///     - Uniswap Protocol  => 15% of each Minting
///     - Governance          => 5% of each Minting
///     - Developers            => 10% of each Minting
///     - NFM Treasury       => 10% of each Minting
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMMinting {
    //include SafeMath
    using SafeMath for uint256;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Owner;
    INfmController public _Controller;
    address private _SController;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    _MonthlyEmissionCount           => Is set to 1, as soon as this reaches 11 it is reset to 1.
    _DailyEmissionCount                => Is set to 0, as soon as this reaches 30 it is reset to 0.
    _dailyBNFTAmount                   => Counts payouts of bonuses issued through minting or NFT minting. The amount is automatically deducted 
                                                            from the daily minting amount and reset to 0.
    _datamintCount                         => Counts all daily minting events.
    _YearlyEmissionAmount            => Sums up all minting amounts within a year for the calculation. Will be reset to 0 at the end of a year.
    _BonusAmount                          => Minting Bonus paid to the executer
    struct Mintings                          => Contains information about the respective minting
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 private _MonthlyEmissionCount = 1;
    uint256 private _DailyEmissionCount;
    uint256 private _dailyBNFTAmount;
    uint256 private _datamintCount = 0;
    uint256 private _YearlyEmissionAmount;
    uint256 private _BonusAmount = 10 * 10**18;
    uint256 private _locked = 0;
    struct Mintings {
        address Sender;
        uint256 amount;
        uint256 timer;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTRACT EVENTS
    Mint (Issuing Address "= address zero", Executor address, Timestamp, issued token amount)
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    event Mint(
        address indexed zero,
        address indexed minter,
        uint256 Time,
        uint256 Amount
    );
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    mintingtable (minting number, Minting information as an Struct. (Executor, minting amount, timestamp));
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(uint256 => Mintings) public mintingtable;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MODIFIER
    onlyOwner       => Only Controller listed Contracts and Owner can interact with this contract.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        require(_locked == 0);
        _locked = 1;
        _;
        _locked = 0;
    }
    

    constructor(address Controller) {
        _Owner = msg.sender;
        _SController = Controller;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _DailyEmissionCount = 0;
        _dailyBNFTAmount = 0;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_updateBNFTAmount(address minter) returns (bool);
    This function is executed on every successful minting. and is responsible for paying out the Minting Bonus.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateBNFTAmount(address minter)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        if (
            block.timestamp <
            INfmTimer(address(_Controller._getTimer()))._getEndMintTime()
        ) {
            IERC20(address(_Controller._getNFM()))._mint(minter, _BonusAmount);
            _dailyBNFTAmount += _BonusAmount;
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @calculateParts(uint256 amount) returns (uint256,uint256,uint256,uint256,uint256);
    This function is executed on every successful minting. and returns the split amounts.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function calculateParts(uint256 amount)
        public
        pure
        returns (
            uint256 UVamount,
            uint256 StakeAmount,
            uint256 GovAmount,
            uint256 DevsAmount,
            uint256 TreasuryAmount
        )
    {
        uint256 onePercent = SafeMath.div(amount, 100);
        uint256 UV = SafeMath.mul(onePercent, 15);
        uint256 ST = SafeMath.mul(onePercent, 60);
        uint256 GV = SafeMath.mul(onePercent, 5);
        uint256 DV = SafeMath.mul(onePercent, 10);
        uint256 TY = SafeMath.sub(amount, (UV + ST + GV + DV));
        return (UV, ST, GV, DV, TY);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @storeMint(address Sender, uint256 amount);
    This function is responsible for mapping the minting
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function storeMint(address Sender, uint256 amount)
        internal
        virtual
        onlyOwner
    {
        mintingtable[_datamintCount] = Mintings(
            Sender,
            amount,
            block.timestamp
        );
        _datamintCount++;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getAllMintings() returns (struct Mintings);
    This function returns information about all mintings that have taken place
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getAllMintings() public view returns (Mintings[] memory) {
        Mintings[] memory lMintings = new Mintings[](_datamintCount);
        for (uint256 i = 0; i < _datamintCount; i++) {
            Mintings storage lMinting = mintingtable[i];
            lMintings[i] = lMinting;
        }
        return lMintings;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getMintingsByElement(uint256 Elements) returns (struct Mintings);
    This function returns information about an minting by Index
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getMintingsByElement(uint256 Elements)
        public
        view
        returns (Mintings memory)
    {
        return mintingtable[Elements];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_minting(address sender) returns (bool);
    This function is responsible for executing the minting logic
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _minting(address sender)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        (uint256 EYearAmount, uint256 EDayAmount) = INfmTimer(
            address(_Controller._getTimer())
        )._getEA();
        uint256 amount = SafeMath.sub(EDayAmount, _dailyBNFTAmount);
        if (_MonthlyEmissionCount == 11 && _DailyEmissionCount == 29) {
            //Check minting amount of the year
            uint256 namount = SafeMath.add(EDayAmount, _YearlyEmissionAmount);
            namount = SafeMath.sub(EYearAmount, namount);
            amount = SafeMath.add(amount, namount);
            _DailyEmissionCount++;
            _YearlyEmissionAmount += amount;
            _dailyBNFTAmount = _BonusAmount;
            (
                uint256 UVamount,
                uint256 StakeAmount,
                uint256 GovAmount,
                uint256 DevsAmount,
                uint256 TreasuryAmount
            ) = calculateParts(SafeMath.sub(amount, 10 * 10**18));
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getUV2Pool(),
                UVamount
            ); // 5%
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getNFMStakingTreasuryERC20(),
                StakeAmount
            ); // 65
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getDaoReserveERC20(),
                GovAmount
            ); // 5%
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getDistribute(),
                DevsAmount
            ); // 10%
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getTreasury(),
                TreasuryAmount
            ); //15%
            IERC20(address(_Controller._getNFM()))._mint(sender, _BonusAmount);
            _dailyBNFTAmount=_BonusAmount;
            storeMint(sender, amount);
            INfmTimer(address(_Controller._getTimer()))._updateDailyMint();
            emit Mint(address(0), sender, block.timestamp, EDayAmount);
            return true;
        } else {
            if (_DailyEmissionCount == 30) {
                _DailyEmissionCount = 1;
                if (_MonthlyEmissionCount == 11) {
                    _MonthlyEmissionCount = 1;
                    _YearlyEmissionAmount = 0;
                } else {
                    _MonthlyEmissionCount++;
                }
                _YearlyEmissionAmount += amount;
            } else {
                _DailyEmissionCount++;
                _YearlyEmissionAmount += amount;
            }
            _dailyBNFTAmount = _BonusAmount;
            (
                uint256 UVamount,
                uint256 StakeAmount,
                uint256 GovAmount,
                uint256 DevsAmount,
                uint256 TreasuryAmount
            ) = calculateParts(SafeMath.sub(amount, 10 * 10**18));
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getUV2Pool(),
                UVamount
            ); // 5%
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getNFMStakingTreasuryERC20(),
                StakeAmount
            ); // 65
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getDaoReserveERC20(),
                GovAmount
            ); // 5%
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getDistribute(),
                DevsAmount
            ); // 10%
            IERC20(address(_Controller._getNFM()))._mint(
                _Controller._getTreasury(),
                TreasuryAmount
            ); //15%
            IERC20(address(_Controller._getNFM()))._mint(sender, _BonusAmount);
            storeMint(sender, amount);
            INfmTimer(address(_Controller._getTimer()))._updateDailyMint();
            emit Mint(address(0), sender, block.timestamp, EDayAmount);
            return true;
        }
    }
}
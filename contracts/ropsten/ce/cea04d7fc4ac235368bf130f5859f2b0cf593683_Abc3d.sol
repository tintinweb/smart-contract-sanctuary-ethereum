pragma solidity ^0.4.24;


contract AbcEvents {
    // fired whenever a player registers a name
    event onNewName(
        uint256 player,
        bool isNewPlayer,
        uint256 affiliate,
        uint256 amountPaid,
        uint256 timeStamp
    );

    // fired at end of buy or reload
    event onEndTx(
        uint256 compressedData,
        uint256 compressedIDs,
        bytes32 playerName,
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount,
        uint256 potAmount,
        uint256 airDropPot
    );

    // fired whenever theres a withdraw
    event onWithdraw(
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

    // fired whenever a withdraw forces end round to be ran
    event onWithdrawAndDistribute(
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
    );

    // fired whenever a player tries a buy after round timer
    // hit zero, and causes end round to be ran.
    event onBuyAndDistribute(
        address playerAddress,
        bytes32 playerName,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
    );

    // fired whenever a player tries a reload after round timer
    // hit zero, and causes end round to be ran.
    event onReLoadAndDistribute(
        address playerAddress,
        bytes32 playerName,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
    );

    // fired whenever an affiliate is paid
    event onAffiliatePayout(
        uint256 indexed affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );

    // received pot swap deposit
    event onPotSwapDeposit(
        uint256 roundID,
        uint256 amountAddedToPot
    );
}


contract modularShort is AbcEvents {
    uint256 public t9 = 1000000000;
    uint256 public t10 = 10000000000;
    uint256 public t17 = 100000000000000000;
    uint256 public t18 = 1000000000000000000;
    uint256 public t19 = 10000000000000000000;
    uint256 public t26 = 100000000000000000000000000;
}

contract Abc3d is modularShort {

    using NameFilter for string;
    using SafeMath for *;
    using ABCKeysCalcLong for uint256;

    //TODO ????????????
    //-------------------------????????????---------------------------------//
    string constant public name = "ABC";
    string constant public symbol = "ABC";

    //-------------???????????????????????????????????????????????????????????????????????????--------//
    uint256 constant private rndInit_ = 30 minutes;
    uint256 constant private rndInc_ = 10 seconds;
    uint256 constant private rndMax_ = 1 hours;

    //-------------------------???????????????-------------------------------//
    mapping(address => uint256) public pIDxAddr_;                                      // (addr => pID)
    mapping(bytes32 => uint256) public pIDxName_;                                      // (name => pID)
    mapping(uint256 => DataSets.Player) public plyr_;                                  // (pID => data)
    mapping(uint256 => mapping(uint256 => DataSets.PlayerRounds)) public plyrRnds_;   // (pID => rID => data)
    mapping(uint256 => mapping(bytes32 => bool)) public plyrNames_;                   // (pID => name => bool)
    mapping(uint256 => mapping(uint256 => bytes32)) public plyrNameList_; // (pID => nameNum => name) list of names a player owns

    //-------------------------??????????????????-----------------------------//
    mapping(uint256 => DataSets.Round) public round_;                                  // (rID => data)
    mapping(uint256 => mapping(uint256 => uint256)) public rndTmEth_;                  // (rID => tID => data) ??????????????????????????????eth

    uint256 public airDropPot_;             // ???????????????
    uint256 public airDropTracker_ = 0;     // ????????????

    uint256 public rID_;    // round id number / total rounds that have happened
    uint256 public pID_;        // total number of players

    //-------------------------????????????--------------------------------//
    mapping(uint256 => DataSets.TeamFee) public fees_;          // (team => fees) fee distribution by team
    mapping(uint256 => DataSets.PotSplit) public potSplit_;     // (team => fees) pot split distribution by team

    //-------------------------???????????????--------------------------
    address community_addr = 0x6d229C76f4752846AC60CF0CFC4741027Ec20355;
    uint256 public registrationFee_ = 10 finney;

    bool public activated_ = false;





    constructor() public {
        fees_[0] = DataSets.TeamFee(30, 0);
        //46% to pot, 20% to aff, 2% to com, 2% to air drop pot
        fees_[1] = DataSets.TeamFee(43, 0);
        //33% to pot, 20% to aff, 2% to com, 2% to air drop pot
        fees_[2] = DataSets.TeamFee(56, 0);
        //20% to pot, 20% to aff, 2% to com, 2% to air drop pot
        fees_[3] = DataSets.TeamFee(43, 8);
        //33% to pot, 20% to aff, 2% to com, 2% to air drop pot

        potSplit_[0] = DataSets.PotSplit(15, 0);
        //48% to winner, 25% to next round, 12% to com
        potSplit_[1] = DataSets.PotSplit(20, 0);
        //48% to winner, 20% to next round, 12% to com
        potSplit_[2] = DataSets.PotSplit(25, 0);
        //48% to winner, 15% to next round, 12% to com
        potSplit_[3] = DataSets.PotSplit(30, 0);
        //48% to winner, 10% to next round, 12% to com
    }

    //TODO ?????????
    /**
     * ?????????????????????????????????????????????????????????????????????
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  ");
        _;
    }

    /**
     * ????????????????????????
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * ????????????????????????
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

    /**
     * ????????????
     */
    function activate() public {
        // only team just can activate
        require(msg.sender == community_addr, "only team just can activate");

        // can only be ran once
        require(activated_ == false, "fomo3d already activated");

        // activate the contract
        activated_ = true;

        // lets start first round
        rID_ = 1;
        round_[1].strt = now;
        round_[1].end = now + rndInit_;
    }

    /**
     * ???????????? TODO ????????????all??????
     */
    function registerNameXID(string _nameString, uint256 _affID) isHuman() public payable {
        require(msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        uint256 _pID = pIDxAddr_[_addr];

        bool _isNewPlayer = registerPID(_addr);

        if (_affID != 0 && _affID != plyr_[_pID].laff && _affID != _pID) {
            // ???????????????
            plyr_[_pID].laff = _affID;
        } else if (_affID == _pID) {
            _affID = 0;
        }
        //??????
        registerName(_pID, _name);
        //TODO ??????,???????????????????????????????????????????????????????????????
        community_addr.transfer(_paid);

        //TODO ????????????,???????????????????????????Stack too deep, try removing local variables.
        emit onNewName(_pID, _isNewPlayer, _affID, _paid, now);
    }

    /**
     * ???????????? - ?????? pid
     */
    function registerPID(address _addr) private returns (bool){
        if (pIDxAddr_[_addr] == 0) {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;

            // set the new player bool to true
            return (true);
        } else {
            return (false);
        }
    }

    /**
     * ???????????? - ?????? name
     */
    function registerName(uint256 _pID, bytes32 _name) private {
        // if names already has been used, require that current msg sender owns the name
        if (pIDxName_[_name] != 0)
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");

        // ????????? plyrNames_,plyr_,plyrNameList_
        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false) {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
            plyrNameList_[_pID][plyr_[_pID].names] = _name;
        }

        //TODO ????????????????????????????????????,??????playerbook?????????
    }

    //TODO ?????? buyXid,reloadXid
    /**
     * ???????????? - ?????? name
     * TODO determinePID ??????
     */
    function buyXid(uint256 _affCode, uint256 _team) isActivated() isHuman() isWithinLimits(msg.value) public payable {
        // set up our tx event data and determine if player is new or not
        DataSets.EventReturns memory _eventData_;

        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID != 0, "need register first");

        // ???????????????
        // ??????????????????????????????????????????????????????
        if (_affCode == 0 || _affCode == _pID) {
            _affCode = plyr_[_pID].laff;

        } else if (_affCode != plyr_[_pID].laff) {
            plyr_[_pID].laff = _affCode;
        }

        _team = verifyTeam(_team);

        buyCore(_pID, _affCode, _team, _eventData_);
    }

    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, DataSets.EventReturns memory _eventData_) private {
        uint256 _rID = rID_;
        uint256 _now = now;

        // ??????????????? ??? ????????????
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) {
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);

        } else {
            // ??????????????????????????????
            if (_now > round_[_rID].end && round_[_rID].ended == false) {
                // ?????? round; ????????????????????????????????????
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                emit onBuyAndDistribute(
                    msg.sender,
                    plyr_[_pID].name,
                    msg.value,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,
                    _eventData_.winnerAddr,
                    _eventData_.winnerName,
                    _eventData_.amountWon,
                    _eventData_.newPot,
                    _eventData_.P3DAmount,
                    _eventData_.genAmount
                );
            }

            // ???????????????????????????gen???
            plyr_[_pID].gen = (plyr_[_pID].gen).add(msg.value);
        }
    }

    /**
     * ????????????????????????????????????????????????eth?????????????????????????????????????????????eth???
     */
    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth) isActivated() isHuman() isWithinLimits(_eth) public {
        // set up our tx event data
        DataSets.EventReturns memory _eventData_;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID != 0, "need register first");

        // ??????????????????????????????????????????????????????
        if (_affCode == 0 || _affCode == _pID) {
            _affCode = plyr_[_pID].laff;
        } else if (_affCode != plyr_[_pID].laff) {
            plyr_[_pID].laff = _affCode;
        }

        _team = verifyTeam(_team);

        reLoadCore(_pID, _affCode, _team, _eth, _eventData_);
    }

    /**
     * @dev ?????????????????????????????????????????????????????????
     * ????????????????????????ETH?????????????????????????????????????????????
     */
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, DataSets.EventReturns memory _eventData_) private {
        uint256 _rID = rID_;
        uint256 _now = now;

        // ??????????????? ??? ????????????
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) {
            // ???all vaults ??????????????????????????????????????? gen vault
            // ?????? safemath library. ????????????????????????????????????eth????????????????????????
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

            // call core
            core(_rID, _pID, _eth, _affID, _team, _eventData_);

            // if round is not active and end round needs to be ran
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire buy and distribute event
            emit onReLoadAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.P3DAmount,
                _eventData_.genAmount
            );
        }
    }

    /**
     * @dev ??????????????????????????????????????????0
     * @return earnings in wei format
     */
    function withdrawEarnings(uint256 _pID) private returns (uint256){
        // ?????? gen vault
        updateGenVault(_pID, plyr_[_pID].lrnd);

        // from vaults
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0) {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return (_earnings);
    }

    /**
     * @dev this is the core logic for any buy/reload that happens while a round
     * is live.
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, DataSets.EventReturns memory _eventData_) private {
        // ?????????????????????????????????
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

        // eth > 100000000
        if (_eth > t9) {

            // mint the new keys
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);

            // ??????????????????1??????????????????
            if (_keys >= t18) {
                updateTimer(_keys, _rID);

                // ??????????????????leader
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;
                if (round_[_rID].team != _team)
                    round_[_rID].team = _team;

                // set the new leader bool to true
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

            // ????????????
            if (_eth >= t17) {
                airDropTracker_++;
                if (airdrop() == true) {
                    uint256 _prize;
                    if (_eth >= t19) {
                        _prize = ((airDropPot_).mul(75)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);

                        // let event know a tier 3 prize was won
                        _eventData_.compressedData += 300000000000000000000000000000000;
                    } else if (_eth >= t18 && _eth < t19) {
                        _prize = ((airDropPot_).mul(50)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);

                        // let event know a tier 2 prize was won
                        _eventData_.compressedData += 200000000000000000000000000000000;
                    } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                        _prize = ((airDropPot_).mul(25)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);

                        // let event know a tier 3 prize was won
                        _eventData_.compressedData += 300000000000000000000000000000000;
                    }
                    // set airdrop happened bool to true
                    _eventData_.compressedData += 10000000000000000000000000000000;
                    // let event know how much was won
                    _eventData_.compressedData += _prize * 1000000000000000000000000000000000;

                    // reset air drop tracker
                    airDropTracker_ = 0;
                }
            }

            // store the air drop tracker number (number of buys since last airdrop)
            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);

            // update player
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            // update round
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

            // distribute eth
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);

            // call end tx function to fire end tx event.
            endTx(_pID, _team, _eth, _keys, _eventData_);
        }
    }

    function managePlayer(uint256 _pID, DataSets.EventReturns memory _eventData_) private returns (DataSets.EventReturns){
        // ????????????????????????????????????, ?????????????????????????????????????????????????????????
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

        // ????????????????????????id
        plyr_[_pID].lrnd = rID_;

        // set the joined round bool to true
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return (_eventData_);
    }

    /**
     * ?????????????????????????????????????????????????????????????????????
     */
    function updateGenVault(uint256 _pID, uint256 _rIDlast) private {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0) {
            // put in gen vault
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // zero out their earnings by updating mask
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }

    /**
     * @dev ?????????????????????unmask??? = ???round_[_rIDlast].mask * plyrRnds_[_pID][_rIDlast].keys???- plyrRnds_[_pID][_rIDlast].mask
     * @return earnings in wei format
     */
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast) private view returns (uint256){
        return ((((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (t18)).sub(plyrRnds_[_pID][_rIDlast].mask));
    }

    /**
     * @dev ?????????????????????????????????
     * @return do we have a winner?
     */
    function airdrop() private view returns (bool){
        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)
            )));
        if ((seed - ((seed / 1000) * 1000)) < airDropTracker_)
            return (true);
        else
            return (false);
    }

    /**
     * 2% ????????????
     * 20% ????????????
     */
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, DataSets.EventReturns memory _eventData_) private returns (DataSets.EventReturns){
        // 2% ????????????
        uint256 _com = _eth / 50;

        // 20% ????????????
        uint256 _aff = _eth / 5;

        // decide what to do with affiliate share of fees
        // affiliate must not be self, and must have a name registered
        if (_affID != _pID && plyr_[_affID].name != '') {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _com = _com.add(_aff);
        }
        community_addr.transfer(_com);

        return (_eventData_);
    }

    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, DataSets.EventReturns memory _eventData_) private returns (DataSets.EventReturns){
        // ??????fees_[_team] ??????gen
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;

        // 2% ?????????
        uint256 _air = (_eth / 50);
        airDropPot_ = airDropPot_.add(_air);

        // (eth = eth - (????????? +  ????????? + ??????))
        _eth = _eth.sub(((_eth.mul(24)) / 100));

        // ??????????????????gen???????????????????????????
        uint256 _pot = _eth.sub(_gen);

        // ???_gen????????? round_[_rID].mask ??? plyrRnds_[_pID][_rID].mask????????????????????????pot
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

        // set up event data
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return (_eventData_);
    }

    /**
     * @dev ??????????????????
     */
    function updateTimer(uint256 _keys, uint256 _rID) private {
        uint256 _now = now;
        uint256 _newTime;

        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);

        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }

    /**
     * @dev ?????????????????????????????????????????????mask
     * @return dust left over
     */
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys) private returns (uint256) {
        /* MASKING NOTES
            earnings masks are a tricky thing for people to wrap their minds around.
            the basic thing to understand here.  is were going to have a global
            tracker based on profit per share for each round, that increases in
            relevant proportion to the increase in share supply.

            the player will have an additional mask that basically says "based
            on the rounds mask, my shares, and how much i've already withdrawn,
            how much is still owed to me?"
        */

        // ???????????????????????????_gen???mask????????????????????????mask??? (dust goes to pot)
        uint256 _ppt = (_gen.mul(t18)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // calculate player earning from their own buy (only based on the keys
        // they just bought).  & update player earnings mask
        // ????????????eth??????_gen???????????????????????????????????????????????????????????????????????????????????????_pearn
        uint256 _pearn = (_ppt.mul(_keys)) / (t18);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (t18)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

        // ?????????????????????
        return (_gen.sub((_ppt.mul(round_[_rID].keys)) / (t18)));
    }

    /**
     * ???????????????????????????
     */
    function endRound(DataSets.EventReturns memory _eventData_) private returns (DataSets.EventReturns){
        uint256 _rID = rID_;
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;
        uint256 _pot = round_[_rID].pot;

        // ?????? winner share, community rewards, gen share and amount reserved for next pot
        // TODO ??????p3d?????????token??????
        uint256 _win = (_pot.mul(48)) / 100;
        uint256 _com = (_pot.mul(3) / 100);
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen));

        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(t18)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / t18);
        if (_dust > 0) {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }

        // ?????????????????????
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // ????????????????????????
        community_addr.transfer(_com);

        // ??????gen????????????keys?????????
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // prepare event data
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * t26) + (_winTID * t17);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.newPot = _res;

        // ???????????????
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_);
        round_[_rID].pot = _res;

        return (_eventData_);
    }

    function verifyTeam(uint256 _team) private pure returns (uint256){
        if (_team < 0 || _team > 3)
            return (2);
        else
            return (_team);
    }

    /**
     * @dev ?????? compression data ??? ??????event
     */
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, DataSets.EventReturns memory _eventData_) private {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit onEndTx(
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            plyr_[_pID].name,
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.P3DAmount,
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }

    //TODO ??????
    /**
     * ?????????key?????????
     */
    function getBuyPrice() public view returns (uint256){
        uint256 _rID = rID_;
        uint256 _now = now;

        // are we in a round?
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ((round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000));
        else // rounds over.  need price for new round
            return (75000000000000);
        // init
    }

    /**
     * ???????????????????????????
     * provider
     * @return time left in seconds
     */
    function getTimeLeft() public view returns (uint256){
        uint256 _rID = rID_;
        uint256 _now = now;

        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt)
                return ((round_[_rID].end).sub(_now));
            else
                return ((round_[_rID].strt).sub(_now));
        else
            return (0);
    }

    /**
     * @dev ???????????????????????????
     * @return winnings vault
     * @return general vault
     * @return affiliate vault
     */
    function getPlayerVaults(uint256 _pID) public view returns (uint256, uint256, uint256){
        // setup local rID
        uint256 _rID = rID_;

        // ??????????????????????????????.  ????????????????????????????????????  (so contract has not distributed winnings)
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0) {
            // ??????????????????
            if (round_[_rID].plyr == _pID) {
                return (
                (plyr_[_pID].win).add(((round_[_rID].pot).mul(48)) / 100),
                (plyr_[_pID].gen).add(getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)),
                plyr_[_pID].aff
                );
                // ??????????????????
            } else {
                return (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)),
                plyr_[_pID].aff
                );
            }

            // ??????????????????????????? ????????????????????????????????????????????????
        } else {
            return (
            plyr_[_pID].win,
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
            plyr_[_pID].aff
            );
        }
    }

    /**
     * ??????????????????????????????keys????????????????????? = plyrRnds_[_pID][_rID].keys * [(pot%)/round_[_rID].keys + round_[_rID].mask]
     * TODO ???????????????????????? plyrRnds_[_pID][_rID].mask ?????????
     */
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID) private view returns(uint256){
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(t18)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / t18)  );
    }

    /**
     * @dev ??????????????????????????????
     */
    function getCurrentRoundInfo() public view returns(uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256){
        uint256 _rID = rID_;

        return (
        _rID,
        round_[_rID].keys,
        round_[_rID].end,
        round_[_rID].strt,
        round_[_rID].pot,
        (round_[_rID].team + (round_[_rID].plyr * 10)),     //?????????????????????id???team id
        plyr_[round_[_rID].plyr].addr,
        plyr_[round_[_rID].plyr].name,
        rndTmEth_[_rID][0],
        rndTmEth_[_rID][1],
        rndTmEth_[_rID][2],
        rndTmEth_[_rID][3],
        airDropTracker_ + (airDropPot_ * 1000)              //13
        );
    }

    /**
     * @dev ????????????????????????????????????????????????msg.sender???
     */
    function getPlayerInfoByAddress(address _addr) public view returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256){
        uint256 _rID = rID_;

        if (_addr == address(0)) {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return (
        _pID,                               //0
        plyr_[_pID].name,                   //1
        plyrRnds_[_pID][_rID].keys,         //2
        plyr_[_pID].win,                    //3
        (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),       //4
        plyr_[_pID].aff,                    //5
        plyrRnds_[_pID][_rID].eth           //???????????????eth??????
        );
    }

    /**
     * @dev ??????eth ???????????????keys
     */
    function calcKeysReceived(uint256 _rID, uint256 _eth) public view returns(uint256){
        uint256 _now = now;

        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth) );
        else
            return ( (_eth).keys() );
    }

    /**
     * @dev ?????????????????????keys????????????eth??????
     */
    function iWantXKeys(uint256 _keys) public view returns(uint256){
        uint256 _rID = rID_;
        uint256 _now = now;

        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else
            return ( (_keys).eth() );
    }
    //TODO ??????
    /**
     * @dev ??????
     */
    function withdraw() isActivated() isHuman() public {
        uint256 _rID = rID_;
        uint256 _now = now;
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _eth;

        // ???????????????????????????????????????
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0) {
            DataSets.EventReturns memory _eventData_;

            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // ????????????
            _eth = withdrawEarnings(_pID);
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // ????????????????????????
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
            emit onWithdrawAndDistribute(
                msg.sender,
                plyr_[_pID].name,
                _eth,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.P3DAmount,
                _eventData_.genAmount
            );

        } else {
            //????????????
            _eth = withdrawEarnings(_pID);
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // fire withdraw event
            emit onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }

}


library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c){
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x) internal pure returns (uint256 y){
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x) internal pure returns (uint256){
        return (mul(x, x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y) internal pure returns (uint256){
        if (x == 0)
            return (0);
        else if (y == 0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++)
                z = mul(z, x);
            return (z);
        }
    }
}

library ABCKeysCalcLong {
    using SafeMath for *;
    /**
     * @dev ???????????????eth???????????????????????????key?????????
     * @param _curEth ???????????????eth??????
     * @param _newEth ????????????eth??????
     * @return x
     */
    function keysRec(uint256 _curEth, uint256 _newEth) internal pure returns (uint256){
        return (keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }

    /**
     * @dev ???????????????keys???????????????????????????eth??????
     * @param _curKeys ????????????keys
     * @param _sellKeys ?????????keys
     * @return x
     */
    function ethRec(uint256 _curKeys, uint256 _sellKeys) internal pure returns (uint256){
        return ((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    /**
     * @dev calculates how many keys would exist with given an amount of eth
     ?????????????????????????????????eth?????????????????????????????????keys
     * @param _eth eth "in contract"
     * @return number of keys that would exist
     */
    function keys(uint256 _eth) internal pure returns (uint256){
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }

    /**
     * @dev calculates how much eth would be in contract given a number of keys
     ?????????????????????????????????keys?????????????????????????????????eth
     * @param _keys number of keys "in contract"
     * @return eth that would exists
     */
    function eth(uint256 _keys) internal pure returns (uint256){
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}


library NameFilter {
    /**
     * @dev filters name strings
     * -???????????????
     * -?????????????????????????????????
     * -????????????????????????????????????
     * -??????????????????
     * -???????????????0x
     * -?????????????????????A-Z, a-z, 0-9, ??????.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input) internal pure returns (bytes32){
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require(_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length - 1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                // require character is a space
                    _temp[i] == 0x20 ||
                // OR lowercase a-z
                (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                // or 0-9
                (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require(_temp[i + 1] != 0x20, "string cannot contain consecutive spaces");

                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

library DataSets {
    /*
     compressedData key
     [76-33][32][31][30][29][28-18][17][16-6][5-3][2][1][0]
     0 - new player (bool)
     1 - joined round (bool)
     2 - new  leader (bool)
     3-5 - air drop tracker (uint 0-999)
     6-16 - round end time
     17 - winnerTeam
     18 - 28 timestamp
     29 - team
     30 - 0 = reinvest (round), 1 = buy (round), 2 = buy (ico), 3 = reinvest (ico)
     31 - airdrop happened bool
     32 - airdrop tier
     33 - airdrop amount won
    compressedIDs key
     [77-52][51-26][25-0]
     0-25 - pID
     26-51 - winPID
     52-77 - rID
    */
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
        bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 P3DAmount;          // amount distributed to p3d
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot
    }

    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 aff;    // affiliate vault

        uint256 laff;   // ?????????id
        uint256 lrnd;   // ?????????round id
        uint256 names;  //
    }

    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask
        uint256 ico;    // ICO phase investment
    }

    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 team;   // tID of team in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
        uint256 ico;    // total eth sent in during ICO phase
        uint256 icoGen; // total eth for gen during ICO phase
        uint256 icoAvg; // average key price for ICO phase
    }

    struct TeamFee {
        uint256 gen;    // % of buy in thats paid to key holders of current round
        uint256 p3d;    // % of buy in thats paid to p3d holders
    }

    struct PotSplit {
        uint256 gen;    // % of pot thats paid to key holders of current round
        uint256 p3d;    // % of pot thats paid to p3d holders
    }

    struct Team {
        uint256 name;
        TeamFee teamFee;
        PotSplit potSplit;
    }
}
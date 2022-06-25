// contracts/Fuel.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IPixelPirates.sol";
import "./ICrew.sol";

contract Treasure is ERC20BurnableUpgradeable, OwnableUpgradeable {
    /*
Some Fancy Treasure Ascii

*/

    using SafeMathUpgradeable for uint256;

    address nullAddress;

    address public pixelPiratesAddress;
    address public crewAddress;

    uint256 totalBattleCount = 1;
    uint256 racerCount = 0;

    uint256 capCode = 111;

    struct Hunt {
        uint256 huntTime;
        uint256 huntPeriod;
        bool exists;
    }

    struct Battle {
        uint256 battleTime;
        uint256 battlePeriod;
        bool isOver;
        uint256 firstCaptain;
        uint256 secondCaptain;
    }

    mapping(uint256 => uint256) internal captainIdToTimeStamp;
    mapping(uint256 => address) internal captainIdToStaker;
    mapping(address => uint256[]) internal stakerToCaptainIds;
    mapping(uint256 => Hunt) internal captainIdToHuntTime;

    mapping(uint256 => Battle) internal battleIdToBattle;
    mapping(uint256 => uint256) internal captainIdToBattleId;

    mapping(uint256 => uint256) internal crewIdToTimeStamp;
    mapping(uint256 => address) internal crewIdToStaker;
    mapping(address => uint256[]) internal stakerToCrewIds;

    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init("Trasuer", "TREASURE");
        nullAddress = 0x0000000000000000000000000000000000000000;
    }

    function setTreasureAddresses(address _pixelPiratesAddress, address _crewAddress)
        public
        onlyOwner
    {
        pixelPiratesAddress = _pixelPiratesAddress;
        crewAddress = _crewAddress;
        return;
    }


    function setCapCode(uint256 newCode) public onlyOwner {
        capCode = newCode;
    }

    /** *********************************** **/
    /** ********* Helper Functions ******* **/
    /** *********************************** **/

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToCaptainIds[staker].length) return;

        for (uint256 i = index; i < stakerToCaptainIds[staker].length - 1; i++) {
            stakerToCaptainIds[staker][i] = stakerToCaptainIds[staker][i + 1];
        }
        stakerToCaptainIds[staker].pop();
    }

    function removeCaptainIdFromStaker(address staker, uint256 captainId) internal {
        for (uint256 i = 0; i < stakerToCaptainIds[staker].length; i++) {
            if (stakerToCaptainIds[staker][i] == captainId) {
                remove(staker, i);
            }
        }
    }

    function removeCrew(address staker, uint256 index) internal {
        if (index >= stakerToCrewIds[staker].length) return;

        for (uint256 i = index; i < stakerToCrewIds[staker].length - 1; i++) {
            stakerToCrewIds[staker][i] = stakerToCrewIds[staker][i + 1];
        }
        stakerToCrewIds[staker].pop();
    }

    function removeCrewIdFromStaker(address staker, uint256 captainId) internal {
        for (uint256 i = 0; i < stakerToCrewIds[staker].length; i++) {
            if (stakerToCrewIds[staker][i] == captainId) {
                removeCrew(staker, i);
            }
        }
    }


    function determineBattleOutcome(uint256 captainId)
        public view
        returns (uint256)
    {

        uint256 battleId = captainIdToBattleId[captainId];
        Battle memory battle = battleIdToBattle[battleId];

        // TODO would do somethin with the battle info

        uint256 battleSum = battle.firstCaptain + battle.secondCaptain;

        return battleSum;


    }



    /** *********************************** **/
    /** ********* Staking Functions ******* **/
    /** *********************************** **/



    function huntWithCaptainsByIds(uint256[] memory captainIds) public {
        for (uint256 i = 0; i < captainIds.length; i++) {
            uint256 captainId = captainIds[i];

            require(
                IERC721(pixelPiratesAddress).ownerOf(captainId) == msg.sender &&
                    captainIdToStaker[captainId] == nullAddress,
                "Captain must be owned by you!"
            );

            IERC721(pixelPiratesAddress).transferFrom(
                msg.sender,
                address(this),
                captainId
            );

            stakerToCaptainIds[msg.sender].push(captainId);

            captainIdToTimeStamp[captainId] = block.timestamp;
            captainIdToStaker[captainId] = msg.sender;

            uint256 numHuntDays = 1;

            uint256 huntPeriod = numHuntDays;
            captainIdToHuntTime[captainId] = Hunt(block.timestamp, huntPeriod, true);
        }
    }



    

    function huntWithCrewByIds(uint256 captainId, uint256[] memory crewIds) public {

        require(
            IERC721(pixelPiratesAddress).ownerOf(captainId) == msg.sender &&
                captainIdToStaker[captainId] == nullAddress,
            "Captain must be owned by you!"
        );

        IERC721(pixelPiratesAddress).transferFrom(
            msg.sender,
            address(this),
            captainId
        );

        stakerToCaptainIds[msg.sender].push(captainId);

        captainIdToTimeStamp[captainId] = block.timestamp;
        captainIdToStaker[captainId] = msg.sender;

        uint256 numHuntDays = 1;

        uint256 huntPeriod = numHuntDays;
        captainIdToHuntTime[captainId] = Hunt(block.timestamp, huntPeriod, true);


        for (uint256 i = 0; i < crewIds.length; i++) {
            uint256 crewId = crewIds[i];

            require(
                IERC721(crewAddress).ownerOf(crewId) == msg.sender &&
                    crewIdToStaker[crewId] == nullAddress,
                "Crew must be stakable by you!"
            );

            IERC721(crewAddress).transferFrom(
                msg.sender,
                address(this),
                crewId
            );

            stakerToCrewIds[msg.sender].push(crewId);

            crewIdToTimeStamp[crewId] = block.timestamp;
            crewIdToStaker[crewId] = msg.sender;
        }
    }


    function battleWithCrewByIds(uint256 captainId, uint256[] memory crewIds) public {

        require(
            IERC721(pixelPiratesAddress).ownerOf(captainId) == msg.sender &&
                captainIdToStaker[captainId] == nullAddress,
            "Captain must be owned by you!"
        );

        IERC721(pixelPiratesAddress).transferFrom(
            msg.sender,
            address(this),
            captainId
        );

        stakerToCaptainIds[msg.sender].push(captainId);

        captainIdToTimeStamp[captainId] = block.timestamp;
        captainIdToStaker[captainId] = msg.sender;

        uint256 numBattleDays = 1;
        uint256 battlePeriod = numBattleDays;

        if (totalBattleCount % 2 == 0) {
            // there should already be an existing battle4
            battleIdToBattle[totalBattleCount-1].secondCaptain = captainId;
            //battleIdToBattle[totalBattleCount] = Battle(block.timestamp, battlePeriod, false);
            captainIdToBattleId[captainId] = totalBattleCount-1;
        } else {
            // create a new battle here for the even numbered player
            battleIdToBattle[totalBattleCount] = Battle(block.timestamp, battlePeriod, false, captainId, 0);
            captainIdToBattleId[captainId] = totalBattleCount;
        }


        totalBattleCount += 1;


        for (uint256 i = 0; i < crewIds.length; i++) {
            uint256 crewId = crewIds[i];

            require(
                IERC721(crewAddress).ownerOf(crewId) == msg.sender &&
                    crewIdToStaker[crewId] == nullAddress,
                "Crew must be stakable by you!"
            );

            IERC721(crewAddress).transferFrom(
                msg.sender,
                address(this),
                crewId
            );

            stakerToCrewIds[msg.sender].push(crewId);

            crewIdToTimeStamp[crewId] = block.timestamp;
            crewIdToStaker[crewId] = msg.sender;
        }
    }


    

    /** *********************************** **/
    /** ********* Unstake Functions ******* **/
    /** *********************************** **/


    function unstakeBattleByIds(uint256 captainId, uint256[] memory crewIds) public {
        uint256 totalRewards = 0;

        require(
            captainIdToStaker[captainId] == msg.sender,
            "Message Sender was not original captain staker for battle!"
        );

        // make sure this captain isn't time locked from hunt stake still

        uint256 bid = captainIdToBattleId[captainId];
        Battle memory b = battleIdToBattle[bid];


        determineBattleOutcome(captainId);
        //uint256 bt = b.battleTime;
        //uint256 bp = b.battlePeriod;
        //uint256 battlePeriodSeconds = bp * 86400;


        /*


        if (b.isOver) {
            // figure out what the outcome was of the battle
            uint256 thing = 2;
        } else {
            determineBattleOutcome(captainId);
        }

        */


        /*
        require(
            block.timestamp > (huntTime + huntPeriodSeconds),
            "Must have raced captain for full race time period"
        );
        */


        uint256 rewardTime;
        rewardTime = 20;


        // TODO: change this to look for tier or speed of captain maybe instead of pay_rate
        //uint8 pay_rate = ICrew(pixelPiratesAddress).getPayForCrew(captainId);
        uint8 pay_rate = 1;
        uint256 stakeTime = block.timestamp - captainIdToTimeStamp[captainId];
        uint256 daysStaked = stakeTime; // / 86400;
        uint256 captainReward = daysStaked * pay_rate;

        IERC721(pixelPiratesAddress).transferFrom(
            address(this),
            msg.sender,
            captainId
        );

        totalRewards += captainReward;

        removeCaptainIdFromStaker(msg.sender, captainId);
        captainIdToStaker[captainId] = nullAddress;

        for (uint256 i = 0; i < crewIds.length; i++) {
            uint256 crewId = crewIds[i];

            require(
                crewIdToStaker[crewId] == msg.sender,
                "Message Sender was not original crew staker!"
            );

            pay_rate = ICrew(crewAddress).getPayForCrew(crewId);
            stakeTime = block.timestamp - crewIdToTimeStamp[crewId];
            daysStaked = stakeTime; // / 86400;
            uint256 crewReward = daysStaked * pay_rate;

            IERC721(crewAddress).transferFrom(
                address(this),
                msg.sender,
                crewId
            );

            totalRewards += crewReward;

            removeCrewIdFromStaker(msg.sender, crewId);
            crewIdToStaker[crewId] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }


    function unstakeCrewsByIds(uint256 captainId, uint256[] memory crewIds) public {
        uint256 totalRewards = 0;

        require(
            captainIdToStaker[captainId] == msg.sender,
            "Message Sender was not original captain staker!"
        );

        // make sure this captain isn't time locked from hunt stake still

        Hunt memory l = captainIdToHuntTime[captainId];
        uint256 huntTime = l.huntTime;
        uint256 huntPeriod = l.huntPeriod;
        // hunt period is in days so we convert to seconds, (60 * 60 * 24 = 86400)
        uint256 huntPeriodSeconds = huntPeriod * 86400;


        /*
        require(
            block.timestamp > (huntTime + huntPeriodSeconds),
            "Must have raced captain for full race time period"
        );
        */


        uint256 rewardTime;
        rewardTime = 20;


        // TODO: change this to look for tier or speed of captain maybe instead of pay_rate
        //uint8 pay_rate = ICrew(pixelPiratesAddress).getPayForCrew(captainId);
        uint8 pay_rate = 1;
        uint256 stakeTime = block.timestamp - captainIdToTimeStamp[captainId];
        uint256 daysStaked = stakeTime; // / 86400;
        uint256 captainReward = daysStaked * pay_rate;

        IERC721(pixelPiratesAddress).transferFrom(
            address(this),
            msg.sender,
            captainId
        );

        totalRewards += captainReward;

        removeCaptainIdFromStaker(msg.sender, captainId);
        captainIdToStaker[captainId] = nullAddress;

        for (uint256 i = 0; i < crewIds.length; i++) {
            uint256 crewId = crewIds[i];

            require(
                crewIdToStaker[crewId] == msg.sender,
                "Message Sender was not original crew staker!"
            );

            pay_rate = ICrew(crewAddress).getPayForCrew(crewId);
            stakeTime = block.timestamp - crewIdToTimeStamp[crewId];
            daysStaked = stakeTime; // / 86400;
            uint256 crewReward = daysStaked * pay_rate;

            IERC721(crewAddress).transferFrom(
                address(this),
                msg.sender,
                crewId
            );

            totalRewards += crewReward;

            removeCrewIdFromStaker(msg.sender, crewId);
            crewIdToStaker[crewId] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }




    function unstakeCaptainsByIds(uint256[] memory captainIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < captainIds.length; i++) {
            uint256 captainId = captainIds[i];

            require(
                captainIdToStaker[captainId] == msg.sender,
                "Message Sender was not original captain staker!"
            );

            // make sure this captain isn't time locked from hunt stake still

            Hunt memory l = captainIdToHuntTime[captainId];
            uint256 huntTime = l.huntTime;
            uint256 huntPeriod = l.huntPeriod;
            // hunt period is in days so we convert to seconds, (60 * 60 * 24 = 86400)
            uint256 huntPeriodSeconds = huntPeriod * 86400;


            /*
            require(
                block.timestamp > (huntTime + huntPeriodSeconds),
                "Must have raced captain for full race time period"
            );
            */


            uint256 rewardTime;
            rewardTime = 20;

            /*

            if (huntTime > 0) { // this should always be true as of now
                rewardTime = (huntTime - captainIdToTimeStamp[captainId]) + (block.timestamp - (huntTime + huntPeriodSeconds));
            }
            */


            // TODO: change this to look for tier or speed of captain maybe instead of pay_rate
            //uint8 pay_rate = ICrew(pixelPiratesAddress).getPayForCrew(captainId);
            uint8 pay_rate = 1;
            uint256 rewardDays = rewardTime; // / 86400;
            uint256 captainReward = rewardTime * pay_rate;

            IERC721(pixelPiratesAddress).transferFrom(
                address(this),
                msg.sender,
                captainId
            );

            totalRewards = totalRewards + captainReward;

            removeCaptainIdFromStaker(msg.sender, captainId);
            captainIdToStaker[captainId] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }


    /** *********************************** **/
    /** ********* Claiming Functions ******* **/
    /** *********************************** **/


    
    function claimByCaptainId(uint256 captainId, uint256 secretCode) public {
        require(
            captainIdToStaker[captainId] == msg.sender,
            "Captain is not claimable by you!"
        );

        // make sure this captain isn't time locked from hunt stake still

        Hunt memory l = captainIdToHuntTime[captainId];
        uint256 huntTime = l.huntTime;
        uint256 huntPeriod = l.huntPeriod;
        // hunt period is in days so we convert to seconds, (60 * 60 * 24 = 86400)
        uint256 huntPeriodSeconds = huntPeriod * 86400;




        // below commented block checks that current time is after the full hunt time
        /*
        require(
            block.timestamp > (huntTime + huntPeriodSeconds),
            "Must have hunted captain for full hunt time seconds"
        );
        */

        uint256 rewardTime = 20;

        /*
        if (huntTime > 0) {
            rewardTime =
                (huntTime - captainIdToTimeStamp[captainId]) +
                (block.timestamp - (huntTime + huntPeriodSeconds));
        } else {
            rewardTime = block.timestamp - captainIdToTimeStamp[captainId];
        }
        */


        uint8 pay_rate = IPixelPirates(pixelPiratesAddress).getPayForCaptain(captainId);
        uint256 rewardDays = rewardTime; // / 86400;

        require(
            rewardDays > 0,
            "must have hunted for at least a day to claim anything"
        );


        uint256 codeMult = 1;

        //require(secretCode == capCode, "sike missed secret code");

        if (secretCode == capCode) codeMult = 2;

        uint256 totalRewards = rewardDays * pay_rate;



        _mint(msg.sender, totalRewards);

        captainIdToTimeStamp[captainId] = block.timestamp;
        captainIdToHuntTime[captainId] = Hunt(0, 0, false);
    }



    function claimByCrew(uint256 captainId, uint256[] memory crewIds) public {
        require(
            captainIdToStaker[captainId] == msg.sender,
            "Captain is not claimable by you!"
        );

        // make sure this captain isn't time locked from hunt stake still

        Hunt memory l = captainIdToHuntTime[captainId];
        uint256 huntTime = l.huntTime;
        uint256 huntPeriod = l.huntPeriod;
        // hunt period is in days so we convert to seconds, (60 * 60 * 24 = 86400)
        uint256 huntPeriodSeconds = huntPeriod * 86400;

        // below commented block checks that current time is after the full hunt time
        /*
        require(
            block.timestamp > (huntTime + huntPeriodSeconds),
            "Must have hunted captain for full hunt time seconds"
        );
        */

        uint256 rewardTime = 20;

        /*
        if (huntTime > 0) {
            rewardTime =
                (huntTime - captainIdToTimeStamp[captainId]) +
                (block.timestamp - (huntTime + huntPeriodSeconds));
        } else {
            rewardTime = block.timestamp - captainIdToTimeStamp[captainId];
        }
        */


        uint8 pay_rate = IPixelPirates(pixelPiratesAddress).getPayForCaptain(captainId);
        uint256 rewardDays = rewardTime; // / 86400;

        require(
            rewardDays > 0,
            "must have hunted for at least a day to claim anything"
        );

        uint256 totalRewards = rewardDays * pay_rate;


        for (uint256 i = 0; i < crewIds.length; i ++) {

            uint256 crew_pay_rate = i;
            totalRewards += (rewardDays * crew_pay_rate);
            crewIdToTimeStamp[crewIds[i]] = block.timestamp;

        }


        _mint(msg.sender, totalRewards);

        captainIdToTimeStamp[captainId] = block.timestamp;
        captainIdToHuntTime[captainId] = Hunt(0, 0, false);
    }

    

    /*


    function claimByCrewId(uint256 crewId) public {
        require(
            crewIdToStaker[crewId] == msg.sender,
            "Crew is not claimable by you!"
        );

        uint8 pay_rate = ICrew(crewAddress).getPayForCrew(crewId);
        uint256 claimTime = block.timestamp - crewIdToTimeStamp[crewId];
        uint256 daysStaked = claimTime; // / 86400;

        require(
            daysStaked > 0,
            "must have staked for at least a day to claim anything"
        );

        _mint(msg.sender, (daysStaked * pay_rate));

        crewIdToTimeStamp[crewId] = block.timestamp;
    }

    function claimAllRewards() public {
        require(
            stakerToCaptainIds[msg.sender].length > 0 ||
                stakerToCrewIds[msg.sender].length > 0,
            "Must have at least one captain or crew staked!"
        );

        uint256 totalRewards = 0;

        for (uint256 i = stakerToCaptainIds[msg.sender].length; i > 0; i--) {
            uint256 captainId = stakerToCaptainIds[msg.sender][i - 1];

            Hunt memory l = captainIdToHuntTime[captainId];
            uint256 huntTime = l.huntTime;
            uint256 huntPeriod = l.huntPeriod;
            // hunt period is in days so we convert to seconds, (60 * 60 * 24 = 86400)
            uint256 huntPeriodSeconds = huntPeriod * 86400;

            //require(block.timestamp > (huntTime + huntPeriodSeconds), "Must have hunted captain for full hunt time seconds");
            if (block.timestamp > (huntTime + huntPeriodSeconds)) {
                uint256 rewardTime;

                if (huntTime > 0) {
                    rewardTime =
                        (huntTime - captainIdToTimeStamp[captainId]) +
                        (block.timestamp - (huntTime + huntPeriodSeconds));
                } else {
                    rewardTime = block.timestamp - captainIdToTimeStamp[captainId];
                }

                uint8 pay_rate = IPixelPirates(pixelPiratesAddress).getPayForCaptain(
                    captainId
                );
                uint256 rewardDays = rewardTime; // / 86400;

                //require (rewardDays > 0, "must have staked for at least a day to claim anything");

                if (rewardDays > 0) {
                    totalRewards = totalRewards + (rewardDays * pay_rate);
                    captainIdToTimeStamp[captainId] = block.timestamp;
                    captainIdToHuntTime[captainId] = Hunt(0, 0, false);
                }
            }
        }

        for (uint256 i = stakerToCrewIds[msg.sender].length; i > 0; i--) {
            uint256 crewId = stakerToCrewIds[msg.sender][i - 1];

            uint8 pay_rate = ICrew(crewAddress).getPayForCrew(crewId);
            uint256 claimTime = block.timestamp - crewIdToTimeStamp[crewId];
            uint256 daysStaked = claimTime; // / 86400;

            //require (daysStaked > 0, "must have staked for at least a day to claim anything");

            if (daysStaked > 0) {
                totalRewards = totalRewards + (daysStaked * pay_rate);
                crewIdToTimeStamp[crewId] = block.timestamp;
            }
        }

        _mint(msg.sender, totalRewards);
    }

    */

    /** *********************************** **/
    /** ********* Public Getters ********** **/
    /** *********************************** **/

    function getCaptainsStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToCaptainIds[staker];
    }

    function getCaptainsHunted(address staker)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory huntCaptains = new uint256[](
            stakerToCaptainIds[staker].length
        );

        for (uint256 i = 0; i < stakerToCaptainIds[staker].length; i++) {
            uint256 captainId = stakerToCaptainIds[staker][i];

            Hunt memory l = captainIdToHuntTime[captainId];
            uint256 huntTime = l.huntTime;
            uint256 huntPeriod = l.huntPeriod;

            if (huntTime > 0 && huntPeriod > 0) {
                //huntCaptains.push(captainId);
                huntCaptains[i] = captainId;
            }
        }

        return huntCaptains;
    }

    function getCrewsStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToCrewIds[staker];
    }

    function getRewardsByCaptainId(uint256 captainId) public view returns (uint256) {
        require(captainIdToStaker[captainId] != nullAddress, "Captain is not staked!");

        Hunt memory l = captainIdToHuntTime[captainId];
        uint256 huntTime = l.huntTime;
        uint256 huntPeriod = l.huntPeriod;
        uint256 huntPeriodSeconds = huntPeriod * 86400;

        require(
            block.timestamp > (huntTime + huntPeriodSeconds),
            "Captain is still hunt time locked so there is no current rewards"
        );

        uint256 rewardTime;

        if (huntTime > 0) {
            rewardTime =
                (huntTime - captainIdToTimeStamp[captainId]) +
                (block.timestamp - (huntTime + huntPeriodSeconds));
        } else {
            rewardTime = block.timestamp - captainIdToTimeStamp[captainId];
        }

        uint8 pay_rate = IPixelPirates(pixelPiratesAddress).getPayForCaptain(captainId);

        uint256 rewardDays = rewardTime; // / 86400;
        uint256 totalRewards = rewardDays * pay_rate;

        return totalRewards;
    }

    function getRewardsByCrewId(uint256 crewId)
        public
        view
        returns (uint256)
    {
        require(
            crewIdToStaker[crewId] != nullAddress,
            "Crew is not staked!"
        );

        uint256 secondsStaked = block.timestamp - crewIdToTimeStamp[crewId];
        uint256 daysStaked = secondsStaked; // / 86400;

        uint8 pay_rate = ICrew(crewAddress).getPayForCrew(crewId);

        return pay_rate * daysStaked;
    }

    function getStaker(uint256 captainId) public view returns (address) {
        return captainIdToStaker[captainId];
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual override {
        uint256 currentAllowance = allowance(account, _msgSender());

        if (_msgSender() != address(crewAddress)) {
            require(
                currentAllowance >= amount,
                "ERC20: burn amount exceeds allowance"
            );
        }

        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// contracts/ICryptoCars.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPixelPirates is IERC721 {
    function getPayForCaptain(uint256 _tokenId) external view returns (uint8);
}

// contracts/ICryptoCars.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICrew is IERC721 {
    function getPayForCrew(uint256 _tokenId) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
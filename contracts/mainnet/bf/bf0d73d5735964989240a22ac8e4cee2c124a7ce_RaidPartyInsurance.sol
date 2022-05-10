// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./RaidPartyInsuranceHelper.sol";

/**
  * @title Insurance Purchaser
  * @author René Hochmuth
  * ฿helper Vitally Marinchenko (vitally.eth)
  */
contract RaidPartyInsurance is RaidPartyInsuranceHelper {

    constructor(
        address _CONFETTI_TOKEN_ADDRESS,
        address _MAIN_GAME_CONTRACT_ADDRESS,
        address _SEEDER_CONTRACT_ADDRESS,
        address _HERO_CONTRACT_ADDRESS,
        address _FIGHTER_CONTRACT_ADDRESS,
        address _REVEAL_HERO_CONTRACT_ADDRESS,
        address _REVEAL_FIGHTER_CONTRACT_ADDRESS
    )
        RaidPartyInsuranceDeclaration(
            _CONFETTI_TOKEN_ADDRESS,
            _REVEAL_FIGHTER_CONTRACT_ADDRESS,
            _MAIN_GAME_CONTRACT_ADDRESS,
            _SEEDER_CONTRACT_ADDRESS,
            _HERO_CONTRACT_ADDRESS,
            _FIGHTER_CONTRACT_ADDRESS,
            _REVEAL_HERO_CONTRACT_ADDRESS
        )
    {
        masterAddress = msg.sender;
    }

    function buyInsuranceFighter(
        uint256 _tokenID,
        uint256 _fighterPos
    )
        registerAllowedCheck
        external
    {
        _buyInsuranceFighter(
            _tokenID,
            _fighterPos
        );
    }

    function buyInsuranceHero(
        uint256 _tokenID
    )
        registerAllowedCheck
        external
    {
        _buyInsuranceHero(
            _tokenID
        );
    }

    function buyInsuranceFighterBulk(
        uint256[] calldata _tokenIDs,
        uint256[] calldata _fighterPositions
    )
        external
    {
        for (uint i = 0; i < _tokenIDs.length; i++) {
            _buyInsuranceFighter(
                _tokenIDs[i],
                _fighterPositions[i]
            );
        }
    }

    function insuranceClaimHero(
        uint256 _tokenID
    )
        external
    {
        _insuranceClaimHero(
            _tokenID
        );
    }

    function insuranceClaimFighter(
        uint256 _tokenID,
        uint256 _fighterPos
    )
        external
    {
        _insuranceClaimFighter(
            _tokenID,
            _fighterPos
        );
    }

    function insuranceClaimFighterBulk(
        uint256[] calldata _tokenIDs,
        uint256[] calldata _fighterPositions
    )
        external
    {
        for (uint i = 0; i < _tokenIDs.length; i++) {
            _insuranceClaimFighter(
                _tokenIDs[i],
                _fighterPositions[i]
            );
        }
    }

    function addConfettiReserve(
        uint256 _amount
    )
        external
    {
        confettiReserves =
        confettiReserves + _amount;

        confettiToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function addFighterReserve(
        uint256 _tokenID
    )
        external
    {
        _addFighterReserve(
            _tokenID
        );
    }

    function addHeroReserve(
        uint256 _tokenID
    )
        external
    {
        _addHeroReserve(
            _tokenID
        );
    }

    function addHeroReserveBulk(
        uint256[] calldata _tokenIDs
    )
        external
    {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            _addHeroReserve(
                _tokenIDs[i]
            );
        }
    }

    function addFighterReserveBulk(
        uint256[] calldata _tokenIDs
    )
        external
    {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            _addFighterReserve(
                _tokenIDs[i]
            );
        }
    }

    function withdrawConfettiAdmin(
        uint256 _amount
    )
        onlyMaster
        external
    {
        confettiReserves -= _amount;
        _determineConfettiCoverageTotal();

        confettiToken.transfer(
            msg.sender,
            _amount
        );
    }

    function withdrawHeroAdmin()
        onlyMaster
        external
    {
        _withdrawHeroAdmin();
    }

    function withdrawHeroAdminBulk(
        uint256 _heroes
    )
        onlyMaster
        external
    {
        for (uint256 i = 0; i < _heroes; i++) {
            _withdrawHeroAdmin();
        }
    }

    function withdrawFighterAdmin()
        onlyMaster
        external
    {
        _withdrawFighterAdmin();
    }

    function withdrawFighterAdminBulk(
        uint256 _fighters
    )
        onlyMaster
        external
    {
        for (uint256 i = 0; i < _fighters; i++) {
            _withdrawFighterAdmin();
        }
    }

    function potentialRegisterIDsUserHero(
        address _user
    )
        external
        view
        returns (uint256)
    {
        uint256 currentHeroID = mainGame.getUserHero(
            _user
        );

        (
            uint256 currentEnhanceCost,
            uint256 batch
        ) = (
            _determineEnhanceCost(
                REVEAL_HERO_CONTRACT_ADDRESS,
                currentHeroID
            ),
            _getBatch()
        );

        (uint256 currentRequestID,) = revealHeroContract.getEnhancementRequest(
            currentHeroID
        );

        try seeder.getSeedSafe(
            REVEAL_HERO_CONTRACT_ADDRESS,
            currentRequestID
        ) {}
        catch
        {
            if (_conditionCheckHero(batch, currentEnhanceCost, currentHeroID)) {
                return currentHeroID;
            }
        }

        return 0;
    }

    function getBatch()
        external
        view
        returns (uint256)
    {
        return _getBatch();
    }

    function activeRemainingFighterReserves()
        external
        view
        returns (uint256)
    {
        uint256 batch = _getBatch();

        return fighterReserves.length
            - fighterReservesPerBatch[batch]
            - fighterReservesPerBatch[batch + 1];
    }

    function activeRemainingHeroReserves()
        external
        view
        returns (uint256)
    {
        uint256 batch = _getBatch();

        return heroReserves.length
            - heroReservesPerBatch[batch]
            - heroReservesPerBatch[batch + 1];
    }

    function potentialRegisterIDsUserFighter(
        address _user
    )
        external
        view
        returns (uint256[] memory)
    {
        (
            uint256 length,
            uint256 currentFighterID,
            uint256 currentEnhanceCost,
            uint256 batch,
            uint256 currentRequestID,
            uint256 k
        ) = (
            mainGame.getUserFighters(_user).length,
            0,
            0,
            _getBatch(),
            0,
            0
        );

        uint256[] memory loadArray = new uint256[](
            length
        );

        for (uint256 i = 0; i < length; i++) {

            currentFighterID = mainGame.getUserFighters(_user)[i];

            currentEnhanceCost = _determineEnhanceCost(
                REVEAL_FIGHTER_CONTRACT_ADDRESS,
                currentFighterID
            );

            (
                currentRequestID,
            ) = revealFighterContract.getEnhancementRequest(
                currentFighterID
            );

            try seeder.getSeedSafe(
                REVEAL_FIGHTER_CONTRACT_ADDRESS,
                currentRequestID
            ) {}
            catch
            {
                if (_conditionCheckFighter(batch, currentFighterID, currentEnhanceCost)) {
                    loadArray[k] = currentFighterID;
                    k += 1;
                }
            }
        }

        uint256[] memory returnArray = new uint256[](k);

        for (uint256 index = 0; index < k; index++) {
            returnArray[index] = loadArray[index];
        }

        return returnArray;
    }

    function changeMaster(
        address _newMaster
    )
        onlyMaster
        external
    {
        masterAddress = _newMaster;
    }

    function enableRegister()
        onlyMaster
        external
    {
        registerAllowed = true;
    }

    function disableRegister()
        onlyMaster
        external
    {
        registerAllowed = false;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    )
        public
        pure
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    function secondsUntilNextBatch()
        external
        view
        returns (
            uint256 nextBatch,
            uint256 timeUntil,
            uint256 timeStamp
        )
    {
        timeStamp = block.timestamp;
        nextBatch = seeder.getNextAvailableBatch();

        timeUntil = nextBatch > timeStamp
            ? nextBatch - timeStamp
            : 0;
    }

    function getCostsHero(
        uint256 _heroID
    )
        external
        view
        returns (
            uint256 enhanceCostHero,
            uint256 insuranceCostHero
        )
    {
        enhanceCostHero = _determineEnhanceCost(
            REVEAL_HERO_CONTRACT_ADDRESS,
            _heroID
        );

        insuranceCostHero = insuranceCostHeroByEnhanceCost[
            enhanceCostHero
        ];
    }

    function getCostsFighter(
        uint256 _fighterID
    )
        external
        view
        returns (
            uint256 enhanceCostFighter,
            uint256 insuranceCostFigther
        )
    {
        enhanceCostFighter = _determineEnhanceCost(
            REVEAL_FIGHTER_CONTRACT_ADDRESS,
            _fighterID
        );

        insuranceCostFigther = insuranceCostFighterByEnhanceCost[
            enhanceCostFighter
        ];
    }

    function getStatsHero(
        uint256 _heroID
    )
        external
        view
        returns (
            uint256 heroDamageMultiplier,
            uint256 heroPartySize,
            uint256 heroUpgradeLevel
        )
    {
        return HeroReveal(REVEAL_HERO_CONTRACT_ADDRESS).getStats(
            _heroID
        );
    }

    function getStatsFighter(
        uint256 _fighterID
    )
        external
        view
        returns (
            uint256 fighterDamageValue,
            uint256 fighterUpgradeLevel
        )
    {
        return FighterReveal(REVEAL_FIGHTER_CONTRACT_ADDRESS).getStats(
            _fighterID
        );
    }
}
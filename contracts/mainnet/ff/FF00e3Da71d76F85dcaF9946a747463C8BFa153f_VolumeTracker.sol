pragma solidity ^0.5.0;

library VolumeTracker {
    struct Observation {
        uint32 blockTimestamp;
        uint128 volCumulative;
    }

    /// @param last The specified observation
    /// @param blockTimestamp The new timestamp
    /// @param tick The active tick
    /// @return Observation The newly populated observation
    function convert(
        Observation memory last,
        uint32 blockTimestamp,
        uint128 tick
    ) private pure returns (Observation memory) {
        return
            Observation({
                blockTimestamp: blockTimestamp,
                volCumulative: last.volCumulative + tick
            });
    }

    /// @param self oracle array
    /// @param index most recent observation index
    /// @param blockTimestamp timestamp of observation
    /// @param tick active tick
    /// @param cardinality populated elements
    /// @return indexUpdated The new index
    function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        uint128 tick,
        uint16 cardinality,
        uint32 minDelta
    ) public returns (uint16 indexUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation in last minDelta seconds
        if (last.blockTimestamp + minDelta >= blockTimestamp) {
            self[index] = convert(last, last.blockTimestamp, tick);
            return index;
        }
        indexUpdated = (index + 1) % cardinality;
        self[indexUpdated] = convert(last, blockTimestamp, tick);
    }

    /// @param self oracle array
    /// @param target targeted timestamp to retrieve value
    /// @param index latest index
    /// @param cardinality populated elements
    function binarySearch(
        Observation[65535] storage self,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt) {
        Observation memory atOrAfter;
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            if (beforeOrAt.blockTimestamp == 0) {
                l = 0;
                r = index;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = beforeOrAt.blockTimestamp <= target;
            bool targetBeforeOrAt = atOrAfter.blockTimestamp >= target;
            if (!targetAtOrAfter) {
                r = i - 1;
                continue;
            } else if (!targetBeforeOrAt) {
                l = i + 1;
                continue;
            }
            break;
        }
    }

    /// @param self oracle array
    /// @param target targeted timestamp to retrieve value
    /// @param index latest index
    /// @param cardinality populated elements
    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt) {

        beforeOrAt = self[index];

        if (beforeOrAt.blockTimestamp <= target) {
            if (beforeOrAt.blockTimestamp == target) {
                return beforeOrAt;
            } else {
                return beforeOrAt;
            }
        }

        beforeOrAt = self[(index + 1) % cardinality];
        if (beforeOrAt.blockTimestamp == 0) beforeOrAt = self[0];
        require(beforeOrAt.blockTimestamp <= target && beforeOrAt.blockTimestamp != 0, "OLD");
        return binarySearch(self, target, index, cardinality);
    }

    function checkLastTradeTime(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        uint16 index
    ) internal view returns (bool) {
        return self[index].blockTimestamp >= time-secondsAgo;
    }

    /// @param self oracle array
    /// @param time current timestamp
    /// @param secondsAgo lookback time
    /// @param index latest index
    /// @param cardinality populated elements
    /// @return volCumulative cumulative volume
    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        uint16 index,
        uint16 cardinality
    ) internal view returns (uint128 volCumulative) {
        if (secondsAgo == 0) {
            Observation memory last = self[index];
            return last.volCumulative;
        }

        uint32 target = time - secondsAgo;

        return getSurroundingObservations(self, target, index, cardinality).volCumulative;
    }

    /// @param self oracle array
    /// @param time current timestamp
    /// @param secondsAgos lookback time
    /// @param index latest index
    /// @param cardinality populated elements
    /// @return volDelta Volume delta based on time period
    function volumeDelta(
        Observation[65535] storage self,
        uint32 time,
        uint32[2] memory secondsAgos,
        uint16 index,
        uint16 cardinality
    ) public view returns (uint128 volDelta) {
        if (!checkLastTradeTime(self, time, secondsAgos[0], index)) return 0; //no trades since the furthest seconds back
        uint128 secondPoint;
        //acts as a way to ensure data is available for new traders. If passed cardinality in reporting then it is fair game for errors as assumptions cannot be made
        if (self[cardinality].volCumulative == 0 && self[1].blockTimestamp > secondsAgos[0]) {
            secondPoint = 0;
        } else { 
            secondPoint = observeSingle(self, time, secondsAgos[0], index, cardinality);
        }
        uint128 firstPoint = observeSingle(self, time, secondsAgos[1], index, cardinality);
        return firstPoint-secondPoint;
    }
}
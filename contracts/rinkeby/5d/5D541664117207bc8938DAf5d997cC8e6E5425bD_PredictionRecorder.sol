// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct Prediction {
    address targetOracle;
    uint targetTime;
    uint creationTime;
    int predictedValue;
    bool isDecrypted;
    address predictionAddress;
    string predictionAuthor;
    string predictionComment;
}

contract PredictionRecorder {
    /**
     * Forecast the value of any address-identifiable oracle to show your expertise.
     * This contract will demonstrate and protect the originality of your predictions.
     * It does so through address-based watermarks and RSA encryption.
     *
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *
     * Basic interaction guide:
     * (off-chain)
     * - have a prediction value for the oracle at some future time (Unix epoch)
     * - generate watermark prefix that does not contain 0
     *   - the watermark is an ordered subset of the digits of your address in base 10
     *   - you are free to choose the length of the watermark for each prediction
     * - generate RSA encryption keys (n, e, d) for your prediction
     * - compute RSA.encrypt(int("<watermark>0<prediction_value>")) with the "e" key
     * (this contract)
     * - submit your encrypted prediction by transacting with makePrediction()
     * - submit a few more using the same RSA keys
     * - you can also change keys, but remember which keys are for which predictions
     * - decrypt your predictions by transacting with decryptPrediction()
     *   -  decryption will expose your keys, be sure to change them afterwards
     * (off-chain)
     * - others can query your predictions through viewPrediction() or EtherScan
     * - others can verify the originality statistics of your predictions through analyzePredictionRecord()
     *   - if a someone copies your predictions, their watermark validity will be poor
     *   - of course, you should replace RSA keys on time and use 6 digits or more on the watermark
     *   - if you don't want to get copied, do not decrypt a prediction if its target time has yet to come
     * - you gain credibility by making good predictions
     *
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *
     * Encryption example:
     * I want to predict a value of 420 for some oracle at timestamp 1652201024.
     * My address is 1520779317728643809679224833904517355724024437910
     *                 | |  |    |   |    |    |
     *                 2 7  3    8   8    9    3 is a valid watermark.
     * My unencrypted prediction is 27388930420. The first 0 is a separator.
     * (n = 1071754013065097, e = 53419426187, d = 20063) is a valid set of RSA keys.
     * My encrypted prediction is (27388930420 ** 53419426187) % 1071754013065097, which is 538266748668477.
     * I predict through makePrediction(1652201024, 538266748668477, "Me", "My comment").
     * Let's say my transaction happened in a block with timestamp at 1652000000.
     * I can decrypt through decryptPrediction(20063, 1071754013065097, 1652000001) or such.
     *
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *
     * Python API in the works: https://pypi.org/project/credict/
     * It uses web3py to interact with Credict contracts.
     * It can help you keep track of local RSA keys and determine encryption batches.
     *
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     */

    address private oracleAddress;
    mapping (address => Prediction[]) private predictions;
    mapping (address => uint) private decryptIndices;
    mapping (address => uint) private numDecryptionBatches;

    constructor(address _oracleAddress) {
        oracleAddress = _oracleAddress;
    }

    /**
     * View the address of the oracle for sanity check.
     */
    function viewOracle() public view returns (address) {
        return oracleAddress;
    }

    /**
     * Make a prediction and keep its record in this contract.
     * The prediction must be RSA encrypted, i.e. c = (m ** e) % n.
     * See: https://en.wikipedia.org/wiki/RSA_(cryptosystem)#Operation
     * If predicting a negative integer, the negative sign is ignored during RSA.
     */
    function makePrediction(
        uint _targetTime,
        int _encryptedPredictedValue,
        string memory _predictionAuthor,
        string memory _predictionComment
    ) external {
        require(block.timestamp < _targetTime, "Cannot predict the past.");

        predictions[msg.sender].push(Prediction({
            targetOracle: oracleAddress,
            targetTime: _targetTime,
            creationTime: block.timestamp,
            predictedValue: _encryptedPredictedValue,
            isDecrypted: false,
            predictionAddress: msg.sender,
            predictionAuthor: _predictionAuthor,
            predictionComment: _predictionComment
        }));
    }

    /**
     * Decrypt predictions so that they become publically readable, i.e. m = (c ** d) % n.
     * This exposes the existing encryption, so the sender must replace their off-chain RSA keys.
     * The option upToCreationTime allows changing keys without having to decrypt previous predictions immediately.
     */
    function decryptPrediction(
        uint d,
        uint n,
        uint upToCreationTime
    ) external returns (uint) {
        address sender = msg.sender;
        uint prevDecryptIndex = decryptIndices[sender];

        /* Pre-compute a near upper bound of log_2(d) for fixed array size */
        uint log2dUpper = logarithmFloor(d, 2) + 1;

        /* Predictions are naturally sorted by their creation time in ascending order */
        for (uint i = decryptIndices[sender]; i < predictions[sender].length; i++) {
            /* If beyond set creation time limit, stop */
            if (predictions[sender][i].creationTime > upToCreationTime) {break;}

            /* Decryption: m = (c ** d) % n with log(d) running time and log(d) memory */
            int sign = predictions[sender][i].predictedValue >= 0 ? int(1) : int(-1);
            uint c = uint(sign * predictions[sender][i].predictedValue);
            uint m = powerWithModulos(c, d, log2dUpper, n);

            /* Finalize struct attribute change */
            predictions[sender][i].predictedValue = sign * int(m);
            predictions[sender][i].isDecrypted = true;
            decryptIndices[sender]++;
        }

        /* If anything got decrypted, increment the batch count */
        if (prevDecryptIndex < decryptIndices[sender]) {numDecryptionBatches[sender]++;}

        return decryptIndices[sender];
    }

    /**
     * View all the predictions made by an address.
     */
    function viewPrediction(address _predictionAddress) public view returns (Prediction[] memory) {
        return predictions[_predictionAddress];
    }

    /**
     * Compare a watermarked value with an address, then parse it.
     * Return a success flag, a length measure, the watermark value, and the actual predicted value.
     */
    function extractWatermark(
        uint watermarkedValue,
        uint[] memory addressDigits
    ) public pure returns (bool, uint, uint, uint) {
        uint[] memory valueDigits = uintToDigits(watermarkedValue);

        /* Initialize return values and processing pointer */
        bool watermarkFlag = true;
        uint watermarkLength = 0;
        uint watermarkValue = 0;
        uint watermarkPointer = 0;

        for (uint i = 0; i < valueDigits.length; i++) {
            /* Watermark normally terminates upon the first 0 encountered */
            if (valueDigits[i] == 0) {
                break;
            }

            /* The watermark must be a "substring" of the integer form of the prediction sender's address */
            while (addressDigits[watermarkPointer] != valueDigits[i]) {
                watermarkPointer++;
                /* If address digits are exhausted, then substring match fails */
                if (watermarkPointer >= addressDigits.length) {
                    watermarkFlag = false;
                    break;
                }
            }

            /* Watermark check has failed: stop */
            if (!watermarkFlag) {break;}

            /* Watermark check continues: shift existing digits to the left and add current digit */
            watermarkValue *= 10;
            watermarkValue += valueDigits[i];
            watermarkLength++;
        }

        uint unwatermarkedValue = 0;
        if (watermarkFlag) {
            for (uint i = watermarkLength + 1; i < valueDigits.length; i++) {
                unwatermarkedValue *= 10;
                unwatermarkedValue += valueDigits[i];
            }
        }

        return (watermarkFlag, watermarkLength, watermarkValue, unwatermarkedValue);
    }

    /**
     * View the prediction records made from an address that fall into a window of target time and creation time.
     */
    function viewPredictionByWindow(
        address _predictionAddress,
        uint _targetTimeStart,
        uint _targetTimeEnd,
        uint _creationTimeStart,
        uint _creationTimeEnd
    ) public view returns (Prediction[] memory) {
        Prediction[] memory storedPredictions = viewPrediction(_predictionAddress);

        /* Find the number of predictions in the window and roughly locate them to save some loop runs */
        uint numInWindow = 0;
        uint firstIdxInWindow = storedPredictions.length + 1;
        uint lastIdxInWindow = 0;
        for (uint i = 0; i < storedPredictions.length; i++) {
            bool windowFlag = (
                _targetTimeStart <= storedPredictions[i].targetTime
                && storedPredictions[i].targetTime <= _targetTimeEnd
                && _creationTimeStart <= storedPredictions[i].creationTime
                && storedPredictions[i].creationTime <= _creationTimeEnd
            );
            if (windowFlag) {
                if (firstIdxInWindow > storedPredictions.length) {firstIdxInWindow = i;}
                lastIdxInWindow = i;
                numInWindow++;
            }
        }

        /* Collect predictions that are in the window */
        Prediction[] memory inWindowPredictions = new Prediction[](numInWindow);
        numInWindow = 0;
        for (uint i = firstIdxInWindow; i < lastIdxInWindow + 1; i++) {
            bool windowFlag = (
                _targetTimeStart <= storedPredictions[i].targetTime
                && storedPredictions[i].targetTime <= _targetTimeEnd
                && _creationTimeStart <= storedPredictions[i].creationTime
                && storedPredictions[i].creationTime <= _creationTimeEnd
            );
            if (windowFlag) {
                inWindowPredictions[numInWindow] = storedPredictions[i];
                numInWindow++;
            }
        }
        return inWindowPredictions;
    }

    /**
     * Analyze prediction records to measure its originality and trustworthiness.
     * Please find these statistics and suggested values in the return statement.
     */
    function analyzePredictionRecord(address _predictionAddress) public view returns (uint, uint, uint, uint, uint) {

        /* We use the integer form of the sender's address to produce (off-contract) and verify (in-contract) watermarks */
        Prediction[] memory storedPredictions = viewPrediction(_predictionAddress);
        uint[] memory addressDigits = uintToDigits(addressToUint(_predictionAddress));

        /* For fewer local variables. [numDecryptedPredictions, numValidWatermarks, totalValidWatermarkLength] */
        uint[] memory intermediateStats = new uint[](3);
        uint[] memory validWatermarks = new uint[](storedPredictions.length);

        /* Decrypted predictions are always to the left of still-encrypted ones */
        for (uint i = 0; i < storedPredictions.length; i++) {
            /* If not yet decrypted, stop */
            if (!storedPredictions[i].isDecrypted) {break;}

            (
                bool watermarkFlag,
                uint watermarkLength,
                uint watermarkValue,
                /* uint unwatermarkedValue */
            ) = extractWatermark(
                /* Take the predicted value without sign */
                uint(storedPredictions[i].predictedValue >= 0 ? storedPredictions[i].predictedValue : -storedPredictions[i].predictedValue),
                addressDigits
            );

            /* Update intermediate statistics */
            intermediateStats[0]++;
            if (watermarkFlag) {
                validWatermarks[intermediateStats[1]] = watermarkValue;
                intermediateStats[1]++;
                intermediateStats[2] += watermarkLength;
            }
        }

        /* Since dynamic mappings are not available, use sorting to count distinct watermarks */
        quickSort(validWatermarks, int(0), int(intermediateStats[1]));

        return (
            /* # decrypted predictions (length of track record, the longer the merrier) */
            intermediateStats[0],
            /* # valid watermarks per 1000 predictions (as close to 1000 as possible) */
            (1000 * intermediateStats[1] / intermediateStats[0]),
            /* # distinct valid watermarks per 1000 predictions (as close to 1000 as possible) */
            (1000 * countDistinctSortedUints(validWatermarks, intermediateStats[1]) / intermediateStats[0]),
            /* average length of valid watermarks per prediction (6-10; too low is bad for security, too high can be costly) */
            intermediateStats[2] / intermediateStats[0],
            /* average predictions per decryption call (4-100; too low is bad for trust, too high can be bad for security) */
            intermediateStats[0] / numDecryptionBatches[_predictionAddress]
        );
    }
}

contract InvitationalBet {
    /**
     * A showcase contract that is a valid application of PredictionRecorder.
     *
     * Invited participants can bet on the oracle value at a specific target time.
     * Before that target time, participants can make new predictions or add their own bet value.
     * For each participant, only the last prediction for the target time will count.
     * To prevent cheating on decryptions, predictions shall contain watermarks that meet a minimum length requirement.
     *
     * Total value of reward pool = sum of values added by all participants
     *
     * After the target time, no predictions can be made. Participants shall decrypt their predictions.
     * They can also pre-check their payoff factor, which is a function of predicted value & true value.
     * If they did not predict or did not meet watermark requirement, the factor is set to 1.
     *
     * At a later time, payoffs to participants will open and anyone can trigger them.
     * It is assumed that all participants have decrypted their predictions.
     * The reward pool will be distributed proportionally to the payoff coeffients:
     *
     * Payoff coefficient = payoff factor * bet value of participant
     */
    PredictionRecorder private recorder;
    AggregatorV3Interface private dataFeed;
    address private recorderAddress;
    address[] private participants;

    uint private targetTime;
    uint private creationCloseTime;
    uint private payOpenTime;
    uint private minWatermarkLength;
    uint private roundTime;
    uint80 private roundId;
    int private trueValue;
    bool private isComplete;

    mapping (address => uint) private isInvited;
    mapping (address => uint) private betValues;

    constructor(
        address _recorderAddress,
        address[] memory _participants,
        uint _targetTime,
        uint _creationCloseTime,
        uint _payOpenTime,
        uint _minWatermarkLength
    ) {
        require(block.timestamp < targetTime, "Cannot target the past.");
        //require(payOpenTime >= targetTime + 72 * 3600, "Give at least 72 hours for post-window decryption.");

        recorder = PredictionRecorder(_recorderAddress);
        dataFeed = AggregatorV3Interface(recorder.viewOracle());
        recorderAddress = _recorderAddress;
        targetTime = _targetTime;
        creationCloseTime = _creationCloseTime;
        payOpenTime = _payOpenTime;
        minWatermarkLength = _minWatermarkLength;

        for (uint i = 1; i < _participants.length; i++) {
            participants.push(_participants[i]);
            isInvited[_participants[i]] = 1;
            betValues[_participants[i]] = 0;
        }

        /* These will be unknown during construction */
        roundTime = 0;
        roundId = 0;
        trueValue = 0;
    }

    modifier onlyInvited() {
        require(isInvited[msg.sender] == 1, "You are not invited.");
        _;
    }

    modifier beforeTargetTime() {
        require(block.timestamp <= targetTime, "Target time has passed.");
        _;
    }

    modifier afterTargetTime() {
        require(targetTime < block.timestamp, "Target time has not passed.");
        _;
    }

    modifier beforeCreationClose() {
        require(block.timestamp <= creationCloseTime, "Creation time has passed.");
        _;
    }

    modifier beforePayOpen() {
        require(block.timestamp < payOpenTime, "Pay is already open.");
        _;
    }

    modifier afterPayOpen() {
        require(payOpenTime <= block.timestamp, "Must wait till pay opens.");
        _;
    }

    modifier beforeComplete() {
        require(!isComplete, "The bet is complete.");
        _;
    }

    /**
     * Basic information for participants to view.
     */
    function viewInfo() public view returns (address, address, uint, uint, uint, uint80, uint, int) {
        return (
            recorderAddress,
            recorder.viewOracle(),
            targetTime,
            payOpenTime,
            minWatermarkLength,
            roundId,
            roundTime,
            trueValue
        );
    }

    /**
     * Add value to one's bet.
     */
    function addValue() external payable onlyInvited beforeCreationClose {
        betValues[msg.sender] += msg.value;
    }

    /**
     * Register a round for oracle lookup that should be the latest one before the target time.
     * If it is not the latest, anyone else can overwrite it.
     */
    function registerRound(uint80 _roundId) public beforePayOpen returns (bool) {
        (
            /* uint80 id */,
            int oracleValue,
            /* uint startedAt */,
            uint timeStamp,
            /* uint80 answeredInRound */
        ) = dataFeed.getRoundData(_roundId);
        if (timeStamp > roundTime && timeStamp <= targetTime) {
            roundId = _roundId;
            roundTime = timeStamp;
            trueValue = oracleValue;
            return true;
        }
        return false;
    }

    /**
     * An example of calculating payoff factors: staircase exponential decay, bounded below by 1.
     * This is unaware of parsing predictions or accounting for invalid prediction values.
     */
    function payFactorFormula(int _predValue, int _trueValue) public pure returns (uint) {
        uint diff = uint(_predValue >= _trueValue ? _predValue - _trueValue : _trueValue - _predValue);
        uint coeff = 2 ** 20;
        for (uint i = 0; i < (diff / 10); i++) {
            coeff /= 2;
        }
        return coeff + 1;
    }

    /**
     * The full pay factor logic, parsing predictions and accounting for invalid prediction values.
     * If there are no predictions or the last prediction does not satisfy watermark requirement,
     * the factor will be 1.
     */
    function computePayFactor(address _participant) private view afterTargetTime returns (uint) {
        require(isInvited[_participant] == 1, "Not a participant");
        /* no prediction made: factor = 1 */
        Prediction[] memory predictions = recorder.viewPredictionByWindow(
            _participant,
            targetTime,
            targetTime,
            0,
            creationCloseTime
        );
        if (predictions.length < 1) {return 1;}

        /* Extract the last predicted value for the target time*/
        Prediction memory lastPrediction = predictions[predictions.length-1];
        uint[] memory addressDigits = uintToDigits(addressToUint(_participant));
        int sign = lastPrediction.predictedValue >= 0 ? int(1) : int(-1);
        (
            bool watermarkFlag,
            uint watermarkLength,
            /* uint watermarkValue */,
            uint unwatermarkedValue
        ) = recorder.extractWatermark(uint(sign * lastPrediction.predictedValue), addressDigits);

        /* watermark is unsatisfactory: factor = 1 */
        if (!watermarkFlag || watermarkLength < minWatermarkLength) {return 1;}

        /* normal scenario: factor is based on the predicted value */
        int predValue = sign * int(unwatermarkedValue);
        return payFactorFormula(predValue, trueValue);
    }

    /**
     * Each participant can check their own pay factor before pay opens.
     */
    function computeMyPayFactor() public view onlyInvited returns (uint) {
        return computePayFactor(msg.sender);
    }

    /**
     * Calculate payoff coefficients for every participant.
     * Payoffs will be delivered proportionally to these coefficients.
     */
    function computeAllPayCoefficients() public view afterPayOpen returns (uint[] memory) {
        uint[] memory payCoefficients = new uint[](participants.length);

        /* Calculate payoff coefficients proportional to bet value */
        for (uint i = 0; i < participants.length; i++) {
            uint factor = computePayFactor(participants[i]);
            payCoefficients[i] = factor * betValues[participants[i]];
        }
        return payCoefficients;
    }

    /**
     * Trigger payoffs. This completes the bet.
     */
    function triggerPay() external payable afterPayOpen beforeComplete {
        uint[] memory payCoefficients = computeAllPayCoefficients();
        uint totalCoefficient = 0;

        for (uint i = 0; i < participants.length; i++) {
            totalCoefficient += payCoefficients[i];
        }

        /* Proceed with payment */
        uint totalAmount = address(this).balance;
        uint cumulCoefficient = 0;
        uint cumulPayment = 0;
        uint nextCumulPayment = 0;

        for (uint i = 0; i < participants.length - 1; i++) {
            cumulCoefficient += payCoefficients[i];
            nextCumulPayment = cumulCoefficient * totalAmount / totalCoefficient;
            uint paymentAmount = nextCumulPayment - cumulPayment;
            payable(participants[i]).transfer(paymentAmount);
            cumulPayment = nextCumulPayment;
        }
        /* For the last participant, avoid rounding error */
        payable(participants[participants.length-1]).transfer(address(this).balance);
        isComplete = true;
    }
}

/* * * * * * * * * * Helper functions go below this line * * * * * * * * * */

/**
 * Quicksort an array in-place.
 */
function quickSort(uint[] memory arr, int left, int right) pure {
    /* Initialize pointers */
    int i = left;
    int j = right;
    if (i==j) {return;}

    /* Partition: below pivot -> left; above pivot -> right */
    uint pivot = arr[uint((left + right) / 2)];
    while (i <= j) {
        while (arr[uint(i)] < pivot) {i++;}
        while (pivot < arr[uint(j)]) {j--;}
        if (i <= j) {
            (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
            i++;
            j--;
        }
    }

    /* Divide and conquer */
    if (left < j) {quickSort(arr, left, j);}
    if (i < right) {quickSort(arr, i, right);}
}

/**
 * Simple integer logarithm, taking the floor.
 */
function logarithmFloor(uint number, uint base) pure returns (uint) {
    require(base >= 2, "Logarithm base must be at least 2.");
    uint logValue = 0;
    while (number >= base) {
        number /= base;
        logValue++;
    }
    return logValue;
}

/**
 * Raise a number to some power while taking modulos.
 */
function powerWithModulos(uint base, uint power, uint log2PowerUpper, uint modulos) pure returns (uint) {
    require(2 ** log2PowerUpper >= power, "Invalid argument value log2PowerUpper");
    /* cache stores base, base**2, base**4, base**8, ... all with % modulos */
    uint[] memory cache = new uint[](log2PowerUpper);
    uint twoToK = 1;
    uint k = 0;
    base = base % modulos;
    uint burner = base;
    while (power >= twoToK) {
        cache[k] = burner;
        twoToK *= 2;
        k += 1;
        burner = (burner * burner) % modulos;
    }
    uint result = 1;
    while (power > 0) {
        while (power < twoToK) {
            twoToK /= 2;
            k -= 1;
        }
        result = (result * cache[k]) % modulos;
        power -= twoToK;
    }
    return result;
}

/**
 * Break a number into digits from left to right.
 */
function uintToDigits(uint number) pure returns (uint[] memory) {
    uint numDigits = 1;
    uint burnerVariable = number;
    while (burnerVariable >= 10) {
        numDigits += 1;
        burnerVariable /= 10;
    }

    uint[] memory digits = new uint[](numDigits);
    burnerVariable = number;
    for (uint i = 0; i < numDigits; i++) {
        digits[numDigits - 1 - i] = burnerVariable % 10;
        burnerVariable /= 10;
    }
    return digits;
}

/**
 * Turn an address into uint form.
 */
function addressToUint(address _address) pure returns (uint) {
    return uint(uint160(_address));
}

/**
 * Count the number of distinct uints in a (portion of) a sorted array.
 */
function countDistinctSortedUints(uint[] memory arr, uint maxIdx) pure returns (uint) {
    if (maxIdx <= 1) {return maxIdx;}
    uint numDistincts = 1;
    for (uint i = 1; i < maxIdx; i++) {
        if (arr[i-1] == arr[i]) {numDistincts++;}
    }
    return numDistincts;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
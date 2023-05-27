// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./BytesLib.sol";
import "./SignedWadMath.sol";
import "./iGUA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";




interface iCurve {
  function getFee(bytes32[] memory _queryhash) external view returns (uint256 fee);
  function getNextMintPrice() external view returns(uint256 price);
  function getNextBurnPrice() external view returns(uint256 price);
  function getCount() external view returns(uint256);
  function getMintPrice(uint256 _x) external view returns(uint256 price);
  function getPosFeePercent18() external view returns(int256);
  function resetCurve(int256 k18_, int256 L18_, int256 b18_, int256 posFeePercent18_, uint256 _reserveBalance) external returns(uint256 newReserve);
  function incrementCount(uint256 _amount) external;
  function decrementCount() external;
  function getNextBurnReward() external view returns(uint256 reward);
}

/** @title BondingCurve Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract BondingCurve is ERC721Holder, Ownable {
  address public _guaContract;
  address public _eetContract;
  bool public _frozen;

  uint256 public _ethReserveBalance;
  uint256 public _k21ReserveBalance;

  address public _k21TokenAddress;

  address public _royaltyRecipient;
  address public _guardians;

  int256 public _posFeeSplitForReferrers18;//% in wad of referrers share of POS

  address public _ethCurve;
  address public _k21Curve;

  bool public _freezeCurves;

  mapping(address => uint256) public _ethPOSBalances;
  mapping(address => uint256) public _k21POSBalances;


  constructor(address ethCurve_, address k21Curve_, address k21TokenAddress_, address initialRecipient_) Ownable(){
    _ethCurve = ethCurve_;
    _k21Curve = k21Curve_;
    _royaltyRecipient = initialRecipient_;
    _guardians = initialRecipient_;
    _k21TokenAddress = k21TokenAddress_;

    _posFeeSplitForReferrers18 = SignedWadMath.wadDiv(15, 100);//0.15 (15%)
  }

  function _setPOSFeeSplit(int256 posFeeSplitForReferrers18_) internal {
    int256 rangeTop = SignedWadMath.wadDiv(50, 100);
    int256 rangeBottom = SignedWadMath.wadDiv(15, 100);
    require(posFeeSplitForReferrers18_ >= rangeBottom && posFeeSplitForReferrers18_ <= rangeTop, "out of range");

    _posFeeSplitForReferrers18 = posFeeSplitForReferrers18_;
  }

  function pay(address _payee, uint256 _amount, uint256 _tokenCount, address _currency, bytes calldata _mintPayload) external payable returns(bool success) {
    int256 amount = int256(_amount);

    if(_currency == address(0)){//ETH
      require(msg.value == _amount, "wrong amount");

      int256 posFee18 = SignedWadMath.wadMul(iCurve(_ethCurve).getPosFeePercent18(), amount);

      //calculate fee split
      uint256 referrerShareOfPOS = uint256(SignedWadMath.wadMul(posFee18, _posFeeSplitForReferrers18));

      uint256 royaltyRecipientShareOfPOS = uint256(posFee18) - referrerShareOfPOS;

      //_royaltyRecipient credited with half POS fee
      _ethPOSBalances[_royaltyRecipient] += royaltyRecipientShareOfPOS;

      //referrer credited with half POS fee (or guardians if no referrer)
      if(_mintPayload.length >= 20){//there is a referrer
        _ethPOSBalances[BytesLib.toAddress(_mintPayload, 0)] += referrerShareOfPOS;
      }else{//no referrer
        _ethPOSBalances[_guardians] += referrerShareOfPOS;
      }

      uint256 reserve = _amount - uint256(posFee18);

      _ethReserveBalance += reserve;

      iCurve(_ethCurve).incrementCount(_tokenCount);
    }else{//K21
      require(_k21TokenAddress == _currency, "only K21");
      bool sent = IERC20(_k21TokenAddress).transferFrom(_payee, address(this), _amount);
      require(sent, "K21 not sent");

      int256 posFee18 = SignedWadMath.wadMul(iCurve(_k21Curve).getPosFeePercent18(), amount);


      //calculate fee split
      uint256 referrerShareOfPOS = uint256(SignedWadMath.wadMul(posFee18, _posFeeSplitForReferrers18));

      uint256 royaltyRecipientShareOfPOS = uint256(posFee18) - referrerShareOfPOS;

      //_royaltyRecipient credited with half POS fee
      _k21POSBalances[_royaltyRecipient] += royaltyRecipientShareOfPOS;

      //referrer credited with half POS fee (or guardians if no referrer)
      if(_mintPayload.length >= 20){//there is a referrer
        _k21POSBalances[BytesLib.toAddress(_mintPayload, 0)] += referrerShareOfPOS;
      }else{//no referrer
        _k21POSBalances[_guardians] += referrerShareOfPOS;
      }

      uint256 reserve = _amount - uint256(posFee18);

      _k21ReserveBalance += reserve;

      iCurve(_k21Curve).incrementCount(_tokenCount);
    }

    success = true;
  }

  function resetCurve(address _currency, int256 k18_, int256 L18_, int256 b18_, int256 posFeePercent18_, int256 posFeeSplitForReferrers18_) external onlyOwner returns(bool success){
    uint256 newReserve;
    if(_currency == address(0)){//EthCurve
      newReserve = iCurve(_ethCurve).resetCurve(k18_, L18_, b18_, posFeePercent18_, _ethReserveBalance);
    }else{//K21Curve
      newReserve = iCurve(_k21Curve).resetCurve(k18_, L18_, b18_, posFeePercent18_, _k21ReserveBalance);
    }

    //update fee split for referrer
    _setPOSFeeSplit(posFeeSplitForReferrers18_);

    return _flush(_currency, newReserve);
  }

  function _flush(address _currency, uint256 _reserve) internal returns(bool success){
    if(_currency == address(0)){//EthCurve
      uint256 ethRelease = _ethReserveBalance - _reserve;
      if(ethRelease > 0){
        int256 ethRelease18 = int256(ethRelease);

        //calculate flush split
        uint256 guardiansShareOfFlush = uint256(SignedWadMath.wadMul(ethRelease18, _posFeeSplitForReferrers18));

        uint256 royaltyRecipientShareOfFlush = uint256(ethRelease18) - guardiansShareOfFlush;

        require(address(this).balance >= royaltyRecipientShareOfFlush, "insuff bal R");

        (bool sent1,) = _royaltyRecipient.call{value: royaltyRecipientShareOfFlush, gas: gasleft()}("");
        require(sent1, "eth tx fail R");

        require(address(this).balance >= guardiansShareOfFlush, "insuff bal G");
        (bool sent2,) = _guardians.call{value: guardiansShareOfFlush, gas: gasleft()}("");
        require(sent2, "eth tx fail G");

        _ethReserveBalance -= ethRelease;//== _reserve
      }
    }else{//K21Curve
      uint256 k21Release = _k21ReserveBalance - _reserve;
      if(k21Release > 0){
        int256 k21Release18 = int256(k21Release);

        //calculate flush split
        uint256 guardiansShareOfFlush = uint256(SignedWadMath.wadMul(k21Release18, _posFeeSplitForReferrers18));

        uint256 royaltyRecipientShareOfFlush = uint256(k21Release18) - guardiansShareOfFlush;

        bool sent1 = IERC20(_k21TokenAddress).transfer(_royaltyRecipient, royaltyRecipientShareOfFlush);
        require(sent1, "k21 tx fail R");
        bool sent2 = IERC20(_k21TokenAddress).transfer(_guardians, guardiansShareOfFlush);
        require(sent2, "k21 tx fail G");

        _k21ReserveBalance -= k21Release;//== _reserve
      }
    }

    success = true;
  }

  function getBalances(address _account) external view returns(uint256 ethBalance, uint256 k21Balance) {
    return (_ethPOSBalances[_account], _k21POSBalances[_account]);
  }

  function withdraw() external returns(bool success) {
    if(_ethPOSBalances[msg.sender] > 0){
      // Use transfer to send Ether to the msg.sender, and handle errors
      (bool transferSuccess, ) = payable(msg.sender).call{value: _ethPOSBalances[msg.sender], gas: gasleft()}("");
      require(transferSuccess, "Ether withdraw fail");

      _ethPOSBalances[msg.sender] = 0; // Update the balance to zero

      success = true;
    }
    if(_k21POSBalances[msg.sender] > 0){
      // Use transfer to send K21 to the msg.sender, and handle errors
      bool transferSuccess = IERC20(_k21TokenAddress).transfer(msg.sender, _k21POSBalances[msg.sender]);
      require(transferSuccess, "K21 withdraw fail");

      _k21POSBalances[msg.sender] = 0; // Update the balance to zero

      success = true;
    }
  }

  function setRoyaltyRecipientAddress(address royaltyRecipient_) external {
    require(msg.sender == _royaltyRecipient, "not auth");
    _royaltyRecipient = royaltyRecipient_;
  }

  function setGuardiansAddress(address guardians_) external {
    require(msg.sender == _guardians, "not auth");
    _guardians = guardians_;
  }

  function setDependencies(address guaContract_, address eetContract_, bool _freeze) external onlyOwner {
    require(!_frozen, "frozen");
    _guaContract = guaContract_;
    _eetContract = eetContract_;
    _frozen = _freeze;
  }

  //Because the bonding curve will be the holder of GUA tokens
  function publishQuery(uint256 _tokenId, string memory _query) external {
    require(msg.sender == IERC721(_eetContract).ownerOf(_tokenId), "EET owner only");
    iGUA(_guaContract).publishQuery(_tokenId, _query);
  }

  function setCurves(address ethCurve_, address k21Curve_, bool _freeze) external onlyOwner {
    require(!_freezeCurves, "frozen");

    _ethCurve = ethCurve_;
    _k21Curve = k21Curve_;

    _freezeCurves = _freeze;
  }

  function transferGUAs(uint256[] memory _tokenIds, address _to, address _theGuaContract) external onlyOwner {
    for(uint256 i = 0; i < _tokenIds.length; i++){
      IERC721(_theGuaContract).safeTransferFrom(address(this), _to, _tokenIds[i]);
    }
  }

  function getFee(uint256 _totalFortunes, address _currency) public view returns (uint256 fee) {
    address curve;
    if(_currency == address(0)){
      curve = _ethCurve;
    }else {
      curve = _k21Curve;
    }

    uint256 count = iCurve(curve).getCount();
    count++;
    for(uint256 i = 0; i < _totalFortunes; i++){
      fee += iCurve(curve).getMintPrice(count++);
    }
  }

  function redeemFortune(uint256 _tokenId, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(bool success){
    require(IERC721(_eetContract).ownerOf(_tokenId) == msg.sender, "not EET owner");

    return iGUA(_guaContract).redeemFortune(_tokenId, _queryhash, _rand, _encrypted);
  }

  function burnTo(uint256 _tokenId, address _owner, address payable _msgSender, address _currency, bytes memory _burnPayload) external returns (bool rewarded) {
    require(msg.sender == _eetContract, "only EET");
    uint256 reward;
    if(_currency == address(0)){
      reward = iCurve(_ethCurve).getNextBurnReward();
      iCurve(_ethCurve).decrementCount();

      (bool sent,) = _msgSender.call{value: reward, gas: gasleft()}("");
      require(sent, "Eth reward fail");

      _ethReserveBalance -= reward;
    }else{
      reward = iCurve(_k21Curve).getNextBurnReward();
      iCurve(_k21Curve).decrementCount();

      require(_k21TokenAddress == _currency, "only K21");
      bool sent = IERC20(_k21TokenAddress).transfer(_msgSender, reward);
      require(sent, "K21 reward fail");

      _k21ReserveBalance -= reward;
    }

    IERC721(_guaContract).safeTransferFrom(address(this), _owner, _tokenId);

    rewarded = true;
  }

}//end

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** @title GUA Interface
  * @author @0xAnimist
  * @notice A collaboration between Cai Guo-Qiang and Kanon
  */
interface iGUA {
  function getData(uint256 _tokenId) external view returns(bytes memory, bytes32 seed, bool queried, string memory encrypted);

  //function getGifs() external view returns(bytes[] memory);

  function tokenAPI(uint256 _tokenId) external view returns(string memory);

  function mint(address _owner, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(uint256 tokenId, bytes32 seed);

  function publishQuery(uint256 _tokenId, string memory _query) external returns (bool published);

  function redeemFortune(uint256 _tokenId, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(bool success);
}//end

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)
library SignedWadMath{
  /// @dev Will not revert on overflow, only use where overflow is not possible.
  function toWadUnsafe(uint256 x) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by 1e18.
          r := mul(x, 1000000000000000000)
      }
  }

  /// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
  /// @dev Will not revert on overflow, only use where overflow is not possible.
  /// @dev Not meant for negative second amounts, it assumes x is positive.
  function toDaysWadUnsafe(uint256 x) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by 1e18 and then divide it by 86400.
          r := div(mul(x, 1000000000000000000), 86400)
      }
  }

  /// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
  /// @dev Will not revert on overflow, only use where overflow is not possible.
  /// @dev Not meant for negative day amounts, it assumes x is positive.
  function fromDaysWadUnsafe(int256 x) public pure returns (uint256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by 86400 and then divide it by 1e18.
          r := div(mul(x, 86400), 1000000000000000000)
      }
  }

  /// @dev Will not revert on overflow, only use where overflow is not possible.
  function unsafeWadMul(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by y and divide by 1e18.
          r := sdiv(mul(x, y), 1000000000000000000)
      }
  }

  /// @dev Will return 0 instead of reverting if y is zero and will
  /// not revert on overflow, only use where overflow is not possible.
  function unsafeWadDiv(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by 1e18 and divide it by y.
          r := sdiv(mul(x, 1000000000000000000), y)
      }
  }

  function wadMul(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Store x * y in r for now.
          r := mul(x, y)

          // Equivalent to require(x == 0 || (x * y) / x == y)
          if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
              revert(0, 0)
          }

          // Scale the result down by 1e18.
          r := sdiv(r, 1000000000000000000)
      }
  }

  function wadDiv(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Store x * 1e18 in r for now.
          r := mul(x, 1000000000000000000)

          // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
          if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
              revert(0, 0)
          }

          // Divide r by y.
          r := sdiv(r, y)
      }
  }

  /// @dev Will not work with negative bases, only use when x is positive.
  function wadPow(int256 x, int256 y) public pure returns (int256) {
      // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
      return wadExp((wadLn(x) * y) / 1e18); // Using ln(x) means x must be greater than 0.
  }

  function wadExp(int256 x) public pure returns (int256 r) {
      unchecked {
          // When the result is < 0.5 we return zero. This happens when
          // x <= floor(log(0.5e18) * 1e18) ~ -42e18
          if (x <= -42139678854452767551) return 0;

          // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
          // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
          if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

          // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
          // for more intermediate precision and a binary basis. This base conversion
          // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
          x = (x << 78) / 5**18;

          // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
          // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
          // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
          int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
          x = x - k * 54916777467707473351141471128;

          // k is in the range [-61, 195].

          // Evaluate using a (6, 7)-term rational approximation.
          // p is made monic, we'll multiply by a scale factor later.
          int256 y = x + 1346386616545796478920950773328;
          y = ((y * x) >> 96) + 57155421227552351082224309758442;
          int256 p = y + x - 94201549194550492254356042504812;
          p = ((p * y) >> 96) + 28719021644029726153956944680412240;
          p = p * x + (4385272521454847904659076985693276 << 96);

          // We leave p in 2**192 basis so we don't need to scale it back up for the division.
          int256 q = x - 2855989394907223263936484059900;
          q = ((q * x) >> 96) + 50020603652535783019961831881945;
          q = ((q * x) >> 96) - 533845033583426703283633433725380;
          q = ((q * x) >> 96) + 3604857256930695427073651918091429;
          q = ((q * x) >> 96) - 14423608567350463180887372962807573;
          q = ((q * x) >> 96) + 26449188498355588339934803723976023;

          /// @solidity memory-safe-assembly
          assembly {
              // Div in assembly because solidity adds a zero check despite the unchecked.
              // The q polynomial won't have zeros in the domain as all its roots are complex.
              // No scaling is necessary because p is already 2**96 too large.
              r := sdiv(p, q)
          }

          // r should be in the range (0.09, 0.25) * 2**96.

          // We now need to multiply r by:
          // * the scale factor s = ~6.031367120.
          // * the 2**k factor from the range reduction.
          // * the 1e18 / 2**96 factor for base conversion.
          // We do this all at once, with an intermediate result in 2**213
          // basis, so the final right shift is always by a positive amount.
          r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
      }
  }

  function wadLn(int256 x) public pure returns (int256 r) {
      unchecked {
          require(x > 0, "UNDEFINED");

          // We want to convert x from 10**18 fixed point to 2**96 fixed point.
          // We do this by multiplying by 2**96 / 10**18. But since
          // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
          // and add ln(2**96 / 10**18) at the end.

          /// @solidity memory-safe-assembly
          assembly {
              r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
              r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
              r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
              r := or(r, shl(4, lt(0xffff, shr(r, x))))
              r := or(r, shl(3, lt(0xff, shr(r, x))))
              r := or(r, shl(2, lt(0xf, shr(r, x))))
              r := or(r, shl(1, lt(0x3, shr(r, x))))
              r := or(r, lt(0x1, shr(r, x)))
          }

          // Reduce range of x to (1, 2) * 2**96
          // ln(2^k * x) = k * ln(2) + ln(x)
          int256 k = r - 96;
          x <<= uint256(159 - k);
          x = int256(uint256(x) >> 159);

          // Evaluate using a (8, 8)-term rational approximation.
          // p is made monic, we will multiply by a scale factor later.
          int256 p = x + 3273285459638523848632254066296;
          p = ((p * x) >> 96) + 24828157081833163892658089445524;
          p = ((p * x) >> 96) + 43456485725739037958740375743393;
          p = ((p * x) >> 96) - 11111509109440967052023855526967;
          p = ((p * x) >> 96) - 45023709667254063763336534515857;
          p = ((p * x) >> 96) - 14706773417378608786704636184526;
          p = p * x - (795164235651350426258249787498 << 96);

          // We leave p in 2**192 basis so we don't need to scale it back up for the division.
          // q is monic by convention.
          int256 q = x + 5573035233440673466300451813936;
          q = ((q * x) >> 96) + 71694874799317883764090561454958;
          q = ((q * x) >> 96) + 283447036172924575727196451306956;
          q = ((q * x) >> 96) + 401686690394027663651624208769553;
          q = ((q * x) >> 96) + 204048457590392012362485061816622;
          q = ((q * x) >> 96) + 31853899698501571402653359427138;
          q = ((q * x) >> 96) + 909429971244387300277376558375;
          /// @solidity memory-safe-assembly
          assembly {
              // Div in assembly because solidity adds a zero check despite the unchecked.
              // The q polynomial is known not to have zeros in the domain.
              // No scaling required because p is already 2**96 too large.
              r := sdiv(p, q)
          }

          // r is in the range (0, 0.125) * 2**96

          // Finalization, we need to:
          // * multiply by the scale factor s = 5.549…
          // * add ln(2**96 / 10**18)
          // * add k * ln(2)
          // * multiply by 10**18 / 2**96 = 5**18 >> 78

          // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
          r *= 1677202110996718588342820967067443963516166;
          // add ln(2) * k * 5e18 * 2**192
          r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
          // add ln(2**96 / 10**18) * 5e18 * 2**192
          r += 600920179829731861736702779321621459595472258049074101567377883020018308;
          // base conversion: mul 2**18 / 2**192
          r >>= 174;
      }
  }

  /// @dev Will return 0 instead of reverting if y is zero.
  function unsafeDiv(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Divide x by y.
          r := sdiv(x, y)
      }
  }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }


    function toHex(bytes memory buffer) public pure returns (string memory) {

        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}
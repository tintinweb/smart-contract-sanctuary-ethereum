// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/** @title Fortunes01 Contract
  * @author @fastackl
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract Fortunes01 {

  uint256 public constant total = 16;

  function getName(uint256 _index) external pure returns (string memory) {
    string[total] memory names = [
      "Moon Mission",
      "Listen for Lambos",
      "Diamonds in the Rough",
      "Nurturing the No-Coiner",
      "HODL",
      "Discord Drama",
      "Apes Assemble",
      "Frens and Fam",
      "Moon Prep",
      "Diamond Duties",
      "Hold My Beer",
      "HODL Hurdles",
      "This is the Way",
      "Brrr",
      "Low-Key Legends",
      "Pepes and Lambos"
    ];

    return names[_index];
  }

  /** @dev Returns the metadata header of the fortune
    * @param _index the index of the fortune
    */
  function metadataHeader(uint256 _index) external pure returns (string memory) {
    string[total] memory fortunes = [
      '{"name": "Moon Mission", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Fire up the rockets. Unstoppable energy and conviction propels you forward. Keep your eyes on the prize and cherish the memes that fuel your journey. Bring out the bullish spirit of the ape within.", "nodes": ["In the genesis block, a seed of potential is planted. Patience young grasshopper - the perfect launchpad requires careful and mindful preparation.", "The roadmap is revealed; the whitepaper gains traction. Unite with fellow apes and seek guidance from legendary diamond hands. All systems are nearly locked and loaded.", "Sleep cancelled. FOMO frenzy intensifies. Ride the pump but don\'t let greed blind you to rugpulls lurking in the shadows. Trust the process and stick to the plan.", "Hold onto your rockets as we soar past ATHs every day. Take some chips off the table. No one ever lost money taking profit.", "Price discovery peaks, crypto influencers shill their bags. Don\'t become someone\'s exit liquidity. Patience and planning underpin long-term hodling.","The top is near. Beware the siren song of 100x YOLOs - greed is the rug pull that has rekt a thousand fortunes."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 1}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Listen for Lambos", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Stay adaptive, listen to the words of the market and mold yourself to crypto\'s ever-shifting landscape. Lambos await those with rock-solid faith and who learn to flow with the market\'s twists and turns.", "nodes": ["Stepping onto the ice, the blockchain solidifies beneath you.","Indomitable, principled, and great - nothing but faith stands between you and generational gainz.","Your latent potential is primed to serve the community. Wait for the right moment.","No fanfare for judicious risk management, just sensible protection.","Your inner grace will usher in abundant gainz.","Forge powerful partnerships as you push up against the boundaries."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 2}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Diamonds in the Rough", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Take the plunge into a fresh journey filled with potential for 100x gainz. But don\'t go all in just yet - be cautious, DYOR, find the inner diamond hands that will guide you through uncharted waters in search of generational wealth.", "nodes": ["Hodl onto your principles with laser eyes. Show respect to fellow frogs and apes to earn true diamond status.","Experiencing resistance? Stay patient and embrace your diamond hands. The moon will shine again after the storm.","Not the time to blindly ape into projects. DYOR and recognize when it\'s time to cut your losses to save your Lambo dreams from crashing.","Keep calm, trade on. Forge alliances with fellow apes, and together, leap toward fortunes untold.","Slowly fill up your bags - small coins require diamond hands, but be cautious with large bags to survive potential rug pulls.","Face adversity with strong hands and a cool head. Remember, even hodlers need breaks - take time for self-care and reflection."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 3}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Nurturing the No-Coiner", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Battle-hardened apes and devs welcome curious no-coiners, eager to explore the crypto frontier. With empathy, patience and wisdom, elder apes help n00bs transform into wise apes one meme at a time.", "nodes": ["Seasoned devs and apes remember: the path to wisdom was not forged alone. Extend a hand and share your learnings with young apes.","Compassionate elder apes spot raw potential in their youthful counterparts. They teach the art of HODL and DYOR, preparing young apes for their quest for tendies.","Avoid the mirage of instant wealth. Beware the temptation of FOMO and the lure of rug pulls. True wealth lies in friendships and relationships that will outlast the darkest of crypto winters.","No-coiners beware: the potential for generational wealth can lure young apes into uncalcuated risks. Elder apes your duty lies in nurturing newcomers - a strong foundation fosters a vibrant, flourishing ecosystem.","From stacking sats to wen lambo, no-coiners absorb the language and humor of crypto, weaving a tapestry of memes and shared knowledge.","The nurturing of no-coiners is a lifelong mission. As crypto\'s trailblazers, it falls on you to forge a path of empathy, understanding and support. Crypto\'s potential lies not just in gainz but in the thriving communities these gainz enable."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 4}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "HODL", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Embrace the HODL mindset as you weather choppy markets. Hone your faith and confidence while you wait for the market to reveal itself to you. Success approaches when strength is not tempted by the dangers that lie ahead.", "nodes": ["Steer clear of YOLO bets and focus on consistent growth through perseverence.","Ignore the FUD and keep a calm, diamond-hand demeanor.","Tread carefully in muddy waters to avoid getting rekt.","The market loves to chop up both bulls and eras. Stay calm, adapt to climb out of the hole.","Self-nourish through the dips, staying steadfast and upright leads to growth.","When unexpected projects appear, consider them carefully and give them respect, ultimately resulting in good fortune."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 5}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Discord Drama", "createdBy": "Cai Guo-Qiang x Kanon", "description":"Squabbles break out as the market chops up both beras and bulls. In a world shrouded by doubt be the voice of reason and unity. Understand the perils of discord and the treasures of shared wisdom.", "nodes": ["When quarrels break out, don\'t FUD the fight. Dial down the drama - a touch of assertion at the right time brings gainz.","No blame or shame from taking cover when outmatched. Don\'t poke the bear, don\'t fight the trend.","Move to stables and focus on the fam while the storm blows over. This too shall pass.","Seek solid ground to subdue the discord. Steadfast sincerity secures profits for posterity.","Approach altercations with neutraility; a balanced stance opens doors to untold gainz.","Clashing for clout? Lame. Fleeting followers will flame out your rocket. The short-lived cred ain\'t worth it, fren."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 6}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Apes Assemble", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Rally the apes to build a force that commands respect. Moon missions and worthy causes require the wisdom of noble elder apes. Unite with devs who embody wisdom, caution and a clear sense of purpose. Together, you\'ll be unstoppable.", "nodes": ["The spark of an idea starts the squad. Shield this tiny ember, stay true to the vision.","Learn from luminaries, exchange insights and craft magic memes to gain momentum. Together, Valhalla is within your grasp.","Dubious degens perhaps take charge, promising utility but craving clicks and quick flips. Keep the crowd under proper guidance, lest your ape army\'s asiprations descend into anarchy.","Retreat, reassess, return. Know when to hit the pause button. A calculated retreat helps conserve resources and realigns the crew.","Swarms of trolls flood the discord spreading FUD. Seek out the wisdom of seasoned sages who can guide the troops through stormy seas.","Relish roaring victories but stand vigilant against overconfidence. Preserve the spirit of camarderie and you\'ll become an unstoppable force."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 7}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Frens and Fam", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Pepes and likeminded frogs assemble to summon the bull. Mutual support and understanding pave the way for joint growth. Embrace sincere connections and collabs; dodge detrimental disputes.", "nodes": ["Genuine bonds fuel lasting frog friendships. Cultivate connected communities, creating an alliance that amplifies prosperity. Good fortune blossoms for united Pepe pursuits.","Discover harmony from within, keep your principles intact. Frens share values and laughs.","Step around alliances with unworthy or self-serving frogs. Risky and deceitful partnerships lead only to chaos and distress.","Seek collabs with acclaimed amphibians aligned with your passions. Leapfrog to success by embracing their experience.","Become the Pepe who inspires unity. Rally frog frens behind common goals, let go of fickle frogs who are ngmi.","Avoid alliances with half-hearted frogs. Lukewarm frens leave frogs mired in mediocrity. True unity demands unwavering commitment."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 8}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Moon Prep", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Crypto isn\'t always about riding the rocket. You\'re entering a phase calling for careful nurturing of skills and gathering of resources. Embrace sincerity and honesty now to ensure smooth sailing during when the bull phase kicks into gear.", "nodes": ["Stay true to the code, secure your path to profits with firm fundamentals.","Frens talk tokenomics, find your co-pilots, navigate smarter together.","Lone forks fade and fizzle, but crypto tribes survive; cherish your allies.","Let your heart be pure and your vision clear and the crypto gods will have your back.","Share the alpha, spread the wealth and let collective success skyrocket.","Take it slow; overtrading will only rek your bags. Balance brings profit."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 9}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Diamond Duties", "createdBy": "Cai Guo-Qiang x Kanon", "description": "When navigating uncharted territory, cautious and mindful action can ensure the successful completion of one\'s duty and one\'s mission, while protecting oneself from danger.", "nodes": ["Stand with the strength of a self-sovereign visionary, humbly wrangling unstoppable innovation into being.","Whether the market is in FOMO or panic mode, walking calmly down the central path brings fortunate outcomes and inner peace.","Avoid FOMO traps and poor decisions. Stay grounded in your objectives.","Deliberate caution in the fog of wild swings results in good fortune. Steer clear of traps on both sides of the order book.","Steadfast commitment to your duties in tough times leads to favorable circumstances.","Celebrate your transformation from no-coiner to hodler, reflect on past actions to ensure future profits."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 10}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Hold My Beer", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Beras confirming their disbelief but Bulls roll their sleeves up to take command. Rally hardworking frens and apes and witness the wealth transfer from paper hands to steadfast diamond hands. The Moon and the Earth\'s vibes are ripe for achieving epic gainz - maintain harmony and a close bond with frens and apes to make the most of the circumstances. ", "nodes": ["Apes together strong. Loyal teammates hold the key to success. United you can conquer the most ruthless of bear markets.","Unfazed by FUD or wild swings, let your diamond hand instincts shine through. Stick to the central path to earn the respect of your peers.","A bearish downturn is only a pit stop on the road to lambos. Stay steadfast, realign, success is yours.","When the beras get a hold, offer encouragement and support to your fellow apes. Let your core values guide your actions.","Befriend the virtuous, join strong communities, and harness the supreme good fortune within your grasp.","Keep calm and HODL on. Recognize the natural cycles of bull and bear; have patience and maintain hope, even amidst liquidations and FUD."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 11}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "HODL Hurdles", "createdBy": "Cai Guo-Qiang x Kanon", "description": "The market giveth and the market taketh away. The relentless and patient outlast the dips. Embrace the fluctuations; keep a level head as you forge ahead.", "nodes": ["Tackling challenges may reveal hidden obstacles. Harness the HODL spirit, and the tide of opportunity comes rolling in.","Don\'t fall prey to Twitter hype; stay grounded in your convictions. Diamond hands focus their gaze, while the masses blindly chase trends.","Even the wisest of apes occasionally get rekt; embrace the rollercoaster ride. Market ups and downs are valuable lessons in disguise.","Trust the unseen forces that have your best interests at heart. Union of frens and frogs ushers in the blessings of shared wisdom.","Break from the pack of paper hands; diamond hands take it to the next-level. The future is on-chain; stay connected to emerging projects.","Break free from setbacks; beyond the dip, hidden gems await. Rise above market doldrums and rocket toward sweet victory; crypto rewards the steadfast."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 12}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "This Is The Way", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Embrace the shared spirit of growth and mutual support. Focus on harmony among peers to overcome obstacles and secure prosperity and progress. Remain committed and upright throughout.", "nodes": ["Dive head-first into collabs. No blame in pursuing connections that embody the spirit of unity.","Break free from the echo chamber. Cultivate connections beyond your comfort zone; prevent self-inflicted disaster and grow your social capital.","Time reveals a steadfast opponent. Bide your time for three years, learning the value of patience and contentment.","When push comes to shove, let integrity and big-brain alpha fuel your decisions. Good fortune shines on those who stand steadfast and true.","Bear raids and FUD may leave battle scars, but with unity come sick gainz, dank memes, and fist pumps. No shame in popping champagne.","Hunt for low cap gems. Unachieved ambitions fuel growth without regrets to hold you back."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 13}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Brrr", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Brrr. The heart of the market beats to the tune of the money printer. You\'re riding waves of green candles and bullish charts, but don\'t forget, moon boys detached from earth\'s reality won\'t win the day. Cool your jets, partner. Amid a bull run, Satoshi\'s wisdom is still king. This ain\'t your grandma\'s Wall Street; this is the wild west of finance. Stay sharp, remember: the biggest hauls don\'t always go to the fattest wallets, but to those who truly respect the code.", "nodes": ["Stay low-key, king. When the market\'s drunk on stimmys, your humility becomes the sobering strategy that keeps you grounded.","Crypto\'s a rich field, but it\'s not a free-for-all. Secure your stack, make your moves wisely. No room for loose cannons here.","Keep good company. Honor the hodlers, the true believers. Dodge the pump-and-dumpers, they\'re just here to stir up dust.","Don\'t let \'Brrr\' muddle your mind. Stay humble, stay alert. Spotting the moment the Fed flips the off switch could be your golden ticket out.","Plain talk goes a long way. In a market rife with noise, honesty stands out. Stay true, inspire others, and good fortune will follow.","In the midst of abundance, don\'t forget to tip your hat. Gratitude\'s the currency of the cosmos, smoothing out the ride in this era of plenty."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 14}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Low-Key Legends", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Achieve legendary crypto status with a low-key approach. Treat fellow market participants as equals, fostering trust and unity within the space. The humble trailblazer leads and inspires the digital masses.", "nodes": ["Have a slice of humble pie while you ride the wild swings. Good fortune awaits.","Stay humble, stay grounded, and fortune will acknowledge your steadfast and upright nature.","Gain respect among communities by working humbly and diligently, attracting blessings and good fortune.","Unshakeable in your humble convictions, shield yourself from the perils of FOMO and market panic.","Prepare for a bull run, but be humble. Savor victory knowing the market offers no guarantees.","Prepare the rocket, but never forget to pack humility. Harmony will fuel our collective moonshot."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 15}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Pepes and Lambos", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Enjoy the thrill of the top, but keep your feet on the ground because eventually the music will stop. Overindulgence and complacency spell disaster. Maintain a humble spirit to secure lasting success.", "nodes": ["Tagging and tweeting every win might make you a meme. Curb your ego or face the risk of becoming a cautionary tale.","Be the hodler who stands firm through both the ups and the downs. Steadfastness leads to fortunes untold.","Staring at your NFT gallery and stalling risks loss. Act promptly and steer clear of remorse.","An impressive portfolio is worth celebrating, but true wealth comes from bonds forged on the blockchain. Hold the fam close.","In times of doubt or low APY, keep pushing forward. Your unwavering commitment will keep you afloat.","As meme coin mania loses momentum, remember to diversify. Adapt and evolve to avoid getting rekt on a fleeting trend."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 16}, {"trait_type": "revealed", "value": "true"}, '
    ];

    return fortunes[_index];
  }

  function totalFortunes() public pure returns (uint256) {
    return total;
  }

}//end

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
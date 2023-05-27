// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/** @title Fortunes02 Contract
  * @author @fastackl
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract Fortunes02 {

  uint256 public constant total = 16;

  function getName(uint256 _index) external pure returns (string memory) {
    string[total] memory names = [
      "Network is Net Worth",
      "Liquidation Liberation",
      "The Chad",
      "Zoom Out",
      "Mind Over Market",
      "Rare Pepe",
      "Rugged and Scammed",
      "Pull Back",
      "White Hat",
      "Stacking Sats",
      "Ramen",
      "Don't Forget to Sell",
      "Bloodbath",
      "Two Buttons",
      "Diamond Duo",
      "Cold Storage"
    ];

    return names[_index];
  }

  /** @dev Returns the metadata header of the fortune
    * @param _index the index of the fortune
    */
  function metadataHeader(uint256 _index) external pure returns (string memory) {
    string[total] memory fortunes = [
      '{"name": "Network is Net Worth", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Good times are a great time to build connections and unify others. Find a balance between your interests and those of the community while staying steadfast and upright. Your network is the iceberg; your net worth is just the tip.", "nodes": ["Change afoot! Uphold truth, good fortune awaits. Spread your message, and solid outcomes follow.","Distracted in goblin town, losing sight of the whales.","Bond with big brains, leave paper hands behind. Embrace synchronicity, seize aspirations. Stand unshakable.", "Ambition paves the way to success; inflexibility provokes loss. Uphold loyalty and balance - the keys to triumph. Articulate aims; disperse doubts.","Unwavering honesty at the height of abundance - good fortune is yours.","Solidify the bonds that matter the most. Kings demonstrate their dedication by donating to DAOs they believe in."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 17}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Liquidation Liberation", "createdBy": "Cai Guo-Qiang x Kanon", "description": "With liquidation comes liberation. After blindly following others without question, a decisive shedding of past mistakes can lead to a refreshed outlook. Flush out past errors, discard outdated strategies, and let go of harmful habits. Pause and reflect for three days before diving in, then forge ahead for three more days to finalize the flush.", "nodes": ["Hack away at decay with unwavering resolve, addressing missteps and persevering through adversity to uncover a renewed fortune.","Release the shackles of your past, embrace balance and progress, and refrain from being trapped in rigidity or dogma.","Minor regrets may arise but do not allow these to escalate into major faults; persevere and learn from your experiences.","Hard pass on the hopium. Short-sighted actions may lead to further instability. Focus on addressing the root of your turmoil.","Embrace supportive allies to rally behind in your quest to transform and reclaim success.","Successfully liberating yourself from past constraints, set your sights on loftier personal and professional goals, emboldened with newfound confidence."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 18}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "The Chad", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Embrace your inner Chad; take the lead and guide the community through the bear and onto collective success. Move quickly and seize opportunities while staying true to core values. Flex your wins but brace for pullbacks in the eight month.", "nodes": ["Anyone with a strong moral compass and unshakeable conviction can be a Chad. Take the lead to secure the stability of collective good fortune.","Foster unity and teamwork to bring good fortune and overcome obstacles, while accepting and respecting that the Chad approach is not for everyone.","Address missteps quickly as you move fast and break things. A mix of diligence and good humor ensures any setbacks are temporary.","Channel your inner goat. Cultivate trust and harmony to build a resilient team you can lead to collective success.","A leader who is wise and humble, and who trusts and empowers everyone to be a Chad, will be rewarded with good fortune and success.","True Chads are honest and sincere. They attract good fortune without fault through unwavering inner rightehousness."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 19}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Zoom Out", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Embrace vigilance in every area of life, from investment moves to personal choices. Strengthen observation skills to make wise decisions and avoid getting rugged.", "nodes": ["Rookies getting rugged is excusable, but diamond hands must strive for clarity.","Hold fast to your values while broadening your perspective. Cultivate a wider understanding without compromising personal integrity.","Choose to ape in or dump out, guided by a strong sense of self-awareness and independent decision-making.","Assess the landscape and align with Goats and Chads. Better decisions come from better understanding.","Remain vigilant, learn from others, and fine-tune your intuition to minimise the rug pulls of life.","Uphold self-reflection and vigilance, both in solitude and in the heat of the game."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 20}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Mind Over Market", "createdBy": "Cai Guo-Qiang x Kanon", "description": "As the market clears out weak hands, seek inner balance to weather the storm. Uphold justice and fairness to maintain harmony and make wise choices during tumultuous times.", "nodes": ["Getting trapped in a position is a learning opportunity to refine your approach and grow. No fault in pushing through.","Uphold your positions and convictions as the market metes out its fiery justice. Help others do the same.","Tough tendies. Grind on, face doubts head-on and you\'ll emerge stronger out the other end.","Persist through the panic. Keep your ear to the ground, maintain your principles and do not relent. Good fortune will follow.","Holding your positions might lead to some drawdowns. Stay true to your course and have faith in your decisions. Your losses are impermanent.","The mind always counts more than profit or loss. If your mind is chained to the ups and downs of the market, you are sure to get rekt."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 21}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Rare Pepe", "createdBy": "Cai Guo-Qiang x Kanon", "description": "In times of abundance, adorn your online presence with Rare Pepe flair. Let the harmonious interaction between your inner Chad and your appreciation for etiquette shine through. A slightly positive outcome is possible if you remain anchored to your true self.", "nodes": ["Hodl onto humility, aligning your actions to your place in the world.","Sowing synergy between shrimp and whales is essential for collective growth.","Receiving help and praise from frens and frogs is beneficial, but it\'s crucial to safeguard your authenticity.","As an enigmatic figure, your humility and openness speak volumes to your peers.","Tower above tribalism and maximalism. Simplicity and self-awareness is the key to success.","As pixels combine to create intricate beauty, so too does your pure essence triumph, devoid of faults."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 22}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Rugged and Scammed", "createdBy": "Cai Guo-Qiang x Kanon", "description": "The integrity of the market is threatened by a succession of rug pulls, malicious exploits and possible exit scams. An excess of greed and lack of due diligence opened the door to these threats.", "nodes": ["Subtle signs of rug pulls emerge, threatening the underlying structure of investments. Unseen hazards take root, inviting peril for unsuspecting investors.","Scams escalate, threatening the moral fabric of crypto. Without ample research and expert guidance, the situation takes a nosedive.","There is no substitute for DYOR. Seek trusted advice to identify secure projects and protect yourself from malicious actors. Taking responsiblity is the only way.","Panic spreads and withdrawals accelerate revealing a gaping hole in the treasury. Drifting dangerously close to causing significant damage to one\'s investments.","Situation turning around, with stronger defenses and informed choices warding off further scams. In the end, tranquility returns and no fault is found.","Emerging from the brink of chaos, a renewed era of vigilance and wisdom dawns. Those who remained virtuous and upright in the depth of the panic will be rewarded."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 23}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Pull Back", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Markets reach astonishing peaks and staggering dips, but you should always remember that after every bear market, the bullish energy eventually returns. Embrace change with proper timing and calculated effort to yield high gainz.", "nodes": ["Proven strategies and long term hodling lead to supreme good fortune. Course correct before going too far to prevent disasters and bitter moments.","When in doubt, zoom out. Embrace the beautiful cycle of the market and let its innate wisdom guide you toward success.","If you\'re on the wrong bus get out at the next stop. Don\'t forget to rest for three days - reversing repeatedly can rek your bags.","Don\'t stray down the path of pump-and-dump shitcoins. Maintain your focus on the fundamentals.","Catch yourself in weak hand moments. Double-check your convictions to protect yourself from regretful panic-selling.","Missing the signals to take profits or buy the dip can bring tough times, but remember, the market is always full of opportunities. Even the hardest of diamond hands have their regrets."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 24}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "White Hat", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Embrace unwavering honesty and sincerity in your actions, considering the benefits to the ecosystem over personal rewards. Let strength and perseverance be your guiding force in overcoming deception and insincerity.", "nodes": ["Hold the line of truth; trust your instincts and be sincere in your actions. Fortune embraces those with genuine intentions, and they shall prosper.","Focus on growing the whole instead of obsessing over personal gains; wealth will follow those who embrace a collaborative spirit.","As challenges emerge, stand tall with white hat ethics. Face adversity with wisdom and grace. Your dedication to the righteous path will guide you.","Be steadfast in your convictions, staying true to the principles that anchor you in authenticity. No FUD can shake you free when you\'re secure in your intent.","Don\'t attempt to fix what isn\'t false. Trust in the interconnectedness of the market and find solace in the solidarity it brings.","Pause, take a step back, and strategize based on your true values. Knowing when to hold or fold is vital in avoiding unnecessary misfortune."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 25}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Stacking Sats", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Embarking on a bold venture to amass expertise, assets and moral fiber. Proceed vigilantly, mindful of over-optimistic actions that could disrupt progress. The blueprint for unshakable success includes gradually building a reservoir of patience, knowledge, virtue. And of course, a stacking sats. This phase paves the way for remarkable achievements, as long as continuous replenishment of resources is pursued.", "nodes": ["Hit the brakes when obstacles arise, using care and contemplation to avert harsher setbacks.","Discover the balance between apeing in and strategic investment. Escaping the FOMO trap preserves long-term growth.","Develop diamond hands - foresee challenges, practice defense, and conquer obstacles with newfound knowledge.","Anticipate potential problems and nurture an arsenal of solutions for undisputed good fortune.","Master smart contracts and address issues at the lowest root cause level to earn the respect of your peers and uncover unexpected opportunities.","Align with the universal teachings, accumulating unmatched wisdom, wealth, and virtues, creating a defined path to preeminence."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 26}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Ramen", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Pass around the bowlfuls of piping hot ramen. To attract good fortune you need to invest time and resources to nourish the body and mind for yourself and others, and thus achieve a virtuous balance.", "nodes": ["Shiny gadgets and trending topics can be tempting snacks, but they spoil the main course. Stay true to your principles and avoid losing sight of what\'s truly important.","Unfortunate outcomes can come from chowing down on shady strategies. Friends, fam, and followers are essential for support - don\'t dine alone!","Seeking success through self-serving tactics will only fill your plate with disaster. It\'s a recipe for misfortune, even if you feel like you\'re cookin\' with gas.","Improvised recipes can lead to sensational wins. Just remember to dish out good vibes and focus on creating a positive outcome for everyone.","Multiple servings of success come from staying upright in the face of challenge. Dare to be bold, but don\'t risk it all for a taste of fleeting fame.","Share your steaming bowl of success with others during hardship. You will be rewarded with good fortune."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 27}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Don\'t Forget to Sell", "createdBy": "Cai Guo-Qiang x Kanon", "description": "The market whispers signals of imbalance and excess euphoria. The decision to sell and take profit sounds easy but is very difficult to handle. This is an opportunity to balance the strengths and weaknesses at play.", "nodes": ["Keep it simple. Buy low, sell high. The ultimate foundation is harder than it sounds but worth the effort.","Growth and renewal are achievable even in the most unlikely situations - let go of strategies that worked in the past.","Stay humble, stay flexible - rigid thinking leads to sagging support.","Improve, evolve, but don\'t lean on others for selling - your friends are not exit liquidity.","Release the quest for a perfect exit; no one ever lost money taking profit.","Tread lightly in the danger zone, and sell with grace when the time is right."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 28}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Bloodbath", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Bounce back stronger and wiser from epic meltdowns by keeping your cool, staying positive and trusting your own inner strength. All losses are temporary unless you die or give up.", "nodes": ["When losses compound, side step spiralling sadness. Keep your head up and hustle through tough times.","When the hole gets bigger and bigger, hone in on smaller victories. Remain vigilant, self-assured, and alert to circumstance.","Drawdowns gap down, danger lurks in your path. Sit tight, wait for the right opportunity to arise.","Simple, sincere acts of kindness and faith can help steer you back to success.","Identify your exit and have the audacity to execute. Avoid a perpetually rekt existence.","Negative vibes are your nemesis, not your partner. Put self-preservation first to survive the darkness and come out stronger and wiser out the other end."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 29}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Two Buttons", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Sometimes it takes deep reflection to identify the correct action that\'s right under your nose. Facing critical decisions, you\'ll rely on courage, intelligence and wit to seize opportunities and to shed light on the correct path. Staying steadfast and righteous, expect a prosperous journey.", "nodes": ["Enthusiasm meets uncertainty - proceed cautiously and respectfully, avoiding pitfalls on the road ahead.","Embrace the golden glow of your inner compass, as staying centered brings ultimate success.","Sunsets and nostalgia may bring sorrow, but focus on the bright side to fend off misfortune.","Markets ebb and flow, just as emotions do; ride the waves, always prepared for change.","Drenched in tears, heavy-hearted - fret not, for the balanced path ushers in better days.","Tackle issues at their core and illuminate the world with faultless action. Like punching the two buttons at once - often the correct action is only obvious after some reflection."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 30}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Diamond Duo", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Two forces merge and take crypto by storm, cementing their place among digital legends. Sincerity in your partnership is the key ingredient, creating a path for boundless harmonious growth.", "nodes": ["Mutual commitment from the get-go leads to immense success.","Weather tough times with patience and flexibility, securing a shared fortune.","Rushing into partnerships without patience creates more trouble than triumph.","Stand tall together and let your resilience outshine potential pitfalls.","Maintain stability even in fleeting encounters by avoiding false platitudes.","Dodge artificial alliances and pixel-thin promises to secure long-lasting success."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 31}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Cold Storage", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Long-lasting endeavors and partnerships require measured steps and unwavering dedication. Like using a cold wallet to commit to hodling assets for the long term, embrace the marathon mentality to achieve long-lasting balance and walk the central path.", "nodes": ["Depth and devotion demand diligence; rushing risks a compromise at the worst possible moment.","Keep your eyes on the long game, remaining true to your principles and objectives. Trust that a deliberate approach will yield success in the end.","Racing toward opportunities without foresight may cause upheaval. Pause to reflect and regroup when facing challenges.","Don\'t venture too far from your core expertise or you risk losing sight of the opportunities uniquely suited to your skillset. Stay rooted to your strengths.","Adapt to the ever-changing landscape, mastering the subtle dance between opportunity and impulse to reap the rewards of your patience.","Moving assets in and out of cold storage often risks compromising the seed. Resist the urge to be swayed by sudden shifts and trends."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 32}, {"trait_type": "revealed", "value": "true"}, '
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
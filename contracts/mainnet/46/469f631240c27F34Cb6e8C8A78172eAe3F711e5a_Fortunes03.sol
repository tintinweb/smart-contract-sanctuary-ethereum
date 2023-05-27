// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/** @title Fortunes03 Contract
  * @author @fastackl
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract Fortunes03 {

  uint256 public constant total = 17;
  //string public constant delimiter = ", ";

  function getName(uint256 _index) external pure returns (string memory) {
    string[total] memory names = [
      "Sell the Rip",
      "BTFD",
      "Send It",
      "Stealth Mode",
      "Vibing Discord",
      "Unleashing Diversity",
      "NGMI",
      "WAGMI",
      "Pizza for Bitcoin",
      "El Salvador",
      "Short Squeeze",
      "Bull Trap",
      "LFG",
      "Pamp It",
      "Max Pain",
      "Token Distro",
      "On the Brink"
    ];

    return names[_index];
  }

  /** @dev Returns the name of the fortune
    * @param _index the index of the fortune
    */
  function metadataHeader(uint256 _index) external pure returns (string memory) {
    string[total] memory fortunes = [
      '{"name": "Sell the Rip", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Street-smart diamond hands hear the subtle sighs of weakness coming from the market. Conserve capital, uphold your integrity and recharge. Your epic comeback is just around the corner.", "nodes": ["Missed the window to dump out? No worries, just focus on staying in control.","Remain steadfast as you pull back - unwavering and balanced.","If you\'re still getting hammered as you try to pull back, concentrate on smaller tasks and care for the crew.","Diamond hands maintain their purity throughout their well-planned retreat, while weak hands cannot detach from the ups and downs of the market.","Embrace the power of retreat as the foundation for future wins.","Take your hands off the market. Halt all involvement, rest, and see yourself conquer."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 33}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "BTFD", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Go all out on the dips, but stay agile and well-anchored.  Embrace restraint when it counts to dodge overconfidence and myopic moves.", "nodes": ["Build a solid base, always prioritizing calculation and authenticity. When risks are considered thoughtfully, fortune favors the patient.","Dips are for buying. Stay true when others lose faith. Navigate the middle path, ensuring stability and growth when it counts.","Rookies charge into the mess, while OGs maintain their composure. Approach chaotically tempting situations with calmness and sober vision.","Achieve lasting prosperity through ethics and determination, not by chasing tempting but unsustainable gains.","Accept the unpredictable nature of the market, and weather losses with equanimity and resolve, preparing for the next opportunity.","Understand that resilience in the face of adversity shapes destiny. Confront difficulties, learn, and watch your bags soar."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 34}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Send It", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Launch your moon mission by advancing with balance and determination. Good fortune is on the horizon if you stay true to yourself. Embrace humility and face setbacks with a healthy dose of humor.", "nodes": ["Don\'t let inexperience hold you back. Stay strong and steady, and you\'ll outrun the bears like a boss.","Don\'t get shaken when support looks like it will give way. Keep your integrity intact and you\'ll find fortune will end up on your side.","Win the trust of those around you and watch regrets disappear. Genuine self-confidence is what\'s fueling your rocket.","Don\'t act without clear goals, and don\'t let greed be your guide. Stay self-aware to avoid becoming the next rug pull victim.","Embrace humility and be receptive to advice. Move forward with confidence and balance to gain support and minimize unfavorable outcomes.","Exercise self-control and keep your eyes on the prize. Good fortune is within reach, but push too hard, and you\'ll become someone\'s exit liquidity."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 35}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Stealth Mode", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Crypto is a dark forest where only the fittest survive. Your brilliance is a secret weapon. When darkness falls, stay courageous and virtuous. Hide your light and bide your time.", "nodes": ["A minor obstacle won\'t derail your journey. Keep moving, but remember to think things through.","When the going gets rough, call upon your network and your unshakeable principles to guide you.","Your secret smarts are your strongest asset. Exercise patience and avoid impulsive choices.","Knowledge is power. Gather intel and use your smarts to steer clear of danger.","Your steadfast integrity will see you through even the darkest times. Stay sharp - use your cunning to outwit the predators in your path.","When the odds seem stacked against you, trust in your principles and values to lead you to triumph."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 36}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Vibing Discord", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Light your server\'s vibes with a winning combo of business and banter. A buzzing, effective and well-grounded community is the key to taking on epic challenges. Embrace your online persona and keep the vibes going, empowering each member to fulfill their roles and grow together.", "nodes": ["Set the server standards high from the get-go to avoid communication breakdowns and foster lasting bonds.","A reliable and grounded admin keeps the chat in check and avoids impulsive decisions.","Balance server moderation with great discussion and banter without losing control.","Be the MVP of the server, keeping everyone entertained and helping others reach their full potential.","Forging close connections leads to server success, reflecting the power of shared understanding.","Keep it genuine, stay humble, and reap the benefits of green candles and a vibrant discord."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 37}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Unleashing Diversity", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Embrace the extreme diversity that thrives on the blockchain. Seek understanding, find common ground, and embrace flexibility to find harmony in this buzzing environment. Discover the extraordinary gift of magic internet friends on the permissionless web.", "nodes": ["Don\'t worry about losing cherished items; true value has a way of returning. Stay alert during unexpected encounters, employing smart tactics for a safe journey.","Show respect when engaging with high-level players. Stay unwavering on your path, preserving your reputation untainted.","Witness unsettling conflicts knowing that even the fiercest exchanges fade away. Unlikely sources often provide the strongest support.","Connect with those who share your values, even in adverse conditions. Blend sincerity with truthfulness to overcome any adversity unscathed.","The moment doubts dissipate, you\'ll find yourself surrounded by magic internet friends for life. Marching ahead together, there\'s no need to worry about tripping over an unseen error.","Approach challenging scenarios with wisdom, first understanding your surroundings. Genuine connections can thrive even in the harshest environments, paving the path to fortune."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 38}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "NGMI", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Margin calls and dwindling runways can make you feel like you\'re ngmi. But don\'t just accept your fate. Look inwards, seek support and take calculated risks. Superior devs, committed to their causes and their communities, can still pull off a Hail Mary. Lower the burn rate; buy some time to take a step back and reassess.", "nodes": ["Expansion with limited capital is a gamble; consolidation brings applause. Bring your burn rate down before making the next bet.","Everyone is feeling the crunch; goats put the interests of others first and take charge of finding a way out.","Throttling up only fast tracks the burn. Instead, return to safety and celebrate the small wins.","Expansion is a high-stakes bet with diminishing chips. Union with staunch supporters and top g allies will open up opportunities and reveal the path out.","Tenacity and virtue attracts powerful new supporters and allies.","Throwing good money after bad is a slippery slope; channeling the wisdom of goats you admire will result in major wins and good fortune."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 39}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "WAGMI", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Relief from margin calls and near death experiences flows with seamless transitions, as long as you stay vigilant for potential setbacks. Embrace the good fortune that\'s coming and remember to keep your head up and eyes open.", "nodes": ["As hardship fades to newfound relief, embrace the change without blame.","Be firm with fraudsters and secure your bounty; steadfastness and integrity open doors of abundance.","Seeking lofty heights under pressure may lead to downfall and disgrace.","Banish shallow connections to make room for meaningful bonds. Sincerity is paramount.","Astute devs who shun superficial connections find fortune and eliminate problems.","Troubles wither and opposition weakens. Dips from here are nothing to fear."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 40}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Pizza for Bitcoin", "createdBy": "Cai Guo-Qiang x Kanon", "description": "The tale of Laszlo, a dev who swapped 10,000 bitcoin for two pizzas in 2010, underscores the importance of identifying when to reduce what is below to increase what is above, to trim the less significant in order to enhance what truly matters.", "nodes": ["Laszlo, a Bitcoin miner, exchanged his rewards for a meal. Remember, sometimes it\'s advantageous to step back for the benefit of others.","10,000 bitcoins for pizzas? Ouch! Hasty decisions can lead to missed opportunities. Patience is a virtue, especially in crypto.","Fortunes fluctuate, but Laszlo\'s legendary transaction is forever. It\'s sometimes best to blaze your own trail.","Laszlo\'s loss paved the way for Bitcoin\'s ascent - he established an enduring precedent for Bitcoin as a medium of exchange. Reducing self-focus can ignite joy and foster positive transformation.","Bitcoin\'s value skyrocketed post-pizza. Welcome unexpected windfalls as a testament to your authenticity.","No regrets for Laszlo, despite the potential fortune squandered. Keep your integrity, support others, and stay true to your journey."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 41}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "El Salvador", "createdBy": "Cai Guo-Qiang x Kanon", "description": "The story of El Salvador\'s bold Bitcoin plunge, which reduced its reliance on traditional fiat systems to uplift its people, illustrates the importance of reducing what is above to increase what is below. Embrace the swiftness of wind when seizing opportunities and the tenacity of thunder as you confront the challenges of fostering collective prosperity.", "nodes": ["El Salvador dives into Bitcoin, making bold strategic moves with potential for immense benefits. No time for regrets.","Embrace unforeseen rewards, staying genuine and committed. Dedicated efforts, like offerings to a nation, bring good fortune.","Pursue balance and open communication to showcase virtuous intentions amid inevitable adoption challenges.","New beginnings are tough; welcome true friends to help overcome shortcomings.","Sincerity and commitment bring good fortune. Stay focused on genuine intentions for your community, unfazed by external reactions.","A wavering heart invites setbacks. Ward off negative influences and distractions, prioritizing inner growth and collective prosperity."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 42}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Short Squeeze", "createdBy": "Cai Guo-Qiang x Kanon", "description": "The market is riddled with wolves, hidden orders and shady moves. Time to light up the charts with your blockchain brilliance. Rally the troops and lay the groundwork for the face-melting squeeze of the century.", "nodes": ["Rushing into a fakeout will get you rekt. Sometimes the best move is not to move. Wait for confirmation.","Stay sharp, watch the whispers, ignore the FUD. With a solid strategy, the night is darkest just before the short squeeze.","Brace yourself for a tough fight ahead to break the shorts. Things could get rough but steadfastness and strength will earn you respect.","Don\'t jump the gun. Trust your gut and heed advice from the top dogs. Don\'t let impatience lead to imprudence.","Hodl fast to your commitment to bust the shorts. It might seem like a long, hard road, but remember, no one ever said making history was easy.","Don\'t wait until the LFG cries fade away to close your position. Buying the top is not allowed."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 43}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Bull Trap", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Sudden price spikes can be tempting but don\'t let FOMO cloud your judgement. Your job is to spot the traps, not fall for them. Keep your community bullish - lead by example and point out the traps as they form.", "nodes": ["Act quick when you see a pump-and-dump forming. Shut it down before the panic sets in.","Don\'t let the FUD infect the chats - you\'re here to keep the spirits high, not low.","Don\'t be discouraged if your message isn\'t getting through. You\'re doing everything you can.","Don\'t isolate yourself from others in frustration. Share insights, share success stories, and you\'ll gather an army of supporters.","FOMO and rot spreads faster than virtue and temperance. Lead by example, your influence counts more than you think.","Don\'t let pride turn you into a bag holder. There\'s no blame in missing a pump - just a lesson to hodl on."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 44}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "LFG", "createdBy": "Cai Guo-Qiang x Kanon", "description": "The secret sauce to a killer community? A badass leader and a rock-solid belief system. When these two powerhouses collide, it\'s like a 10,000% APY yield farm - people can\'t resist pooling their resources together, fueled by unity and determination. This potent combo sparks unstoppable vibes, forging communities that are ready to face whatever crypto throws at them. LFG!", "nodes": ["In crypto\'s murky waters, stay true. Authenticity is your FUD-free bridge to a strong community.","Wallet size doesn\'t matter; heart integrity does. Stick to principles for a guaranteed moonshot.","Even off track, the grind continues. The bull run isn\'t perfect, but bullish winds favor the persistent.","Your heart is in the right place, even if you\'re not quite feeling the vibe. Tread carefully, bridge gaps, and stay determined.","Shining leadership and superior positioning brighten your resolve. Hold firm to the central path, let regret dissolve.","Stranded in a bear market, it\'s not the whales or the market that\'s to blame. Examine your motivations and actions."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 45}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Pamp It", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Ready to level up? The scene\'s ripe for a power move. But remember, your network\'s your net worth. Your squad is your muscle, your ticket to the top. If you\'re gunning for the summit, remember to keep it real. No one\'s buying what you\'re selling if you\'re not.", "nodes": ["You\'re all in for the climb, the peak\'s in sight. The big guns? They\'re backing your play.","Keep it straight, and watch the rewards roll in. Small victories, big victories, it\'s all progress. Play fair, play clean.","Unexplored terrain is the name of the game - don\'t back down. Keep grinding.","Trust is your capital. Earn it, from the top dogs to the underdogs. It\'s all good, no regrets.","Stay steady, stay upright, and watch your success story unfold, every chapter of it, one chapter at a time.","Even when the market cools, stay locked in. Keep your spirit high and your strategy tight. But be careful not to burn out - you can\'t win if you\'re out of the game."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 46}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Max Pain", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Welcome to the crypto winter, where the bloodbath\'s more intense than a Tarantino flick. These are the times when every dancing Doge turns into a sad Pepe, but hold on. Winter\'s just the end of one cycle and the start of another. It\'s not about posting copium memes or doom scrolling. It\'s about grit. The bear market isn\'t a death sentence; it\'s an opportunity to rise from the ashes.", "nodes": ["When you\'re in the darkest hour, remember, even Batman had to go through a lot before he became the Dark Knight.","Remember, a diamond is just a piece of charcoal that handled stress exceptionally well. Time to shine, diamond hands!","When it feels like you\'re trapped in your own home, remember, no one promised you a bed of roses. Welcome to life outside the citadel.","When your bags are heavy, don\'t get bitter, get better. This is the winter of your discontent, but spring will come. Eventually.","When the moon seems unreachable, remember, stars are still visible on the darkest nights. Keep your eyes on the sky - it\'ll keep things in persepective.","Every mistake is a lesson learned. Every loss is an opportunity gained. Remember, it\'s not about how hard you can hit, it\'s about how hard you can get hit and keep moving forward."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 47}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Token Distro", "createdBy": "Cai Guo-Qiang x Kanon", "description": "After a marathon coding session, our digital warriors need rejuvenation. The cure? A token distribution. But it\'s more than just token handouts. It\'s about rewarding the deserving. Let\'s plunge into this token journey, shall we?", "nodes": ["Tokens in the gutter, project\'s pulse is low. Change is inevitable though. Adjust, adapt, and watch the well refill.","Tokens are mere drops in the ocean, unnoticed. The flawed distribution strategy isn\'t helping.","We\'ve attempted a fix, but it\'s still off. Remember, the deserving may go unnoticed, but patience is key.","Distribution revamped, not flooding the market yet. Gear up for the future, seize the day post-overhaul.","The foolproof distribution is ready, tokens are set to roll. With resilience and the right mindset, one can take the world by storm.","Token distribution in full swing, system humming perfectly. It\'s not just about just tokens, it\'s about creating harmony."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 48}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "On the Brink", "createdBy": "Cai Guo-Qiang x Kanon", "description": "We\'re on the edge of a digital dawn, where the old is booted out and the new is booted up. We\'re talking about a tech revolution that\'s not just breaking down the past, but also building the future. This revolution is coded in the DNA of the blockchain and the will of the people. When the revolution is rooted in truth, all \'coulda, woulda, shouldas\' fade away, making the grand exit of the old system a sight to behold!", "nodes": ["Hold your horses, or rather, hodl your coins. It\'s not time to trade yet. Stay low, stack sats and gather your crypto clan.","The market is ripe for disruption. Make your move and you\'ll be showered with sats and high fives.","Don\'t rush, or you\'ll crash. Straight shooting and transparency are the name of the game in this blockchain revolution.","When you\'re steadfast in your cause, doubt dissolves. Repeat and reinforce your beliefs to rally the crypto crew, sparking a bull run of epic proportions.","A true crypto king rides the wave of change with flair. When you\'re true to the crypto creed, you don\'t need a crystal ball.","The wise hodler advances with a clear strategy; the noobs follow the hodler\'s strategy for a taste of crypto glory."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 49}, {"trait_type": "revealed", "value": "true"}, '
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
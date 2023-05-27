// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/** @title Fortunes04 Contract
  * @author @fastackl
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract Fortunes04 {

  uint256 public constant total = 15;
  //string public constant delimiter = ", ";

  function getName(uint256 _index) external pure returns (string memory) {
    string[total] memory names = [
      "The Bitcoin Standard",
      "Max Long",
      "Touch Grass",
      "Proof of Work",
      "Golden Arches",
      "Fat Tendies",
      "Double Top",
      "Trend is your Friend",
      "Cat Vibing",
      "Correction",
      "Quantitative Tightening",
      "Diamond Core",
      "Reducing Leverage",
      "The Top",
      "The Bottom"
    ];

    return names[_index];
  }

  /** @dev Returns the name of the fortune
    * @param _index the index of the fortune
    */
  function metadataHeader(uint256 _index) external pure returns (string memory) {
    string[total] memory fortunes = [
      '{"name": "The Bitcoin Standard", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Major mojo when morphing the old into the new. The crypto revolution isn\'t just about swapping fiat for digital, it\'s about creating a 100x better system. Tossing out the traditional is tough; setting up the new is even tougher. You need the wisdom of a white-hat and the heart of an OG hodler. So respect and reward your devs and ditch the duds.", "nodes": ["Shaking off the shackles of the old order, shedding the stagnant, and shadowing Satoshi leads to a faultless future.","Profits pop up when you\'re picky about your paths and your partners. Play it safe and the payoffs will be plentiful.","A minor glitch is gumming up the gears of greatness. Debug the dilemma and delete your doubts. Good fortune is firing up.","Never hand the hot seat to a half-baked hack. If you do, you\'re just begging for bugs in your soup.","Rally the righteous and the resourceful when the bear market bares its teeth. Steer clear, stand tall, stay true, and you\'ll outsmart the beras.","When the long-term lions and the short-term sharks sync up, you\'re sailing to success."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 50}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Max Long", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Strap in, it\'s time to go Max Long. The stakes couldn\'t be higher. Seizing the moment is crucial, but it\'s the methodical strategist who often strikes gold. The time for your power play is now, yet patience and prudence must pilot the process. With a cool head and a vigilant heart, prepare to make the trade of your lifetime.", "nodes": ["It\'s the first tick of the trade and your pulse is racing. Stay alert, process the rush, and let the lessons of the past guide your next move.","Don\'t sweat drawdowns. With a clear head and a patient strategy, the market will swing back in your favor. Just give it seven days.","Portfolio looks promising. But don\'t let early gains make you reckless. Maintain vigilance, constantly reassess, and ensure your approach remains grounded in reality.","Hold your ground. Keep your focus and remember, the path will clear for those who persist.","When market winds shift unfavorably, that\'s when your character is truly tested. Stay calm, evaluate your position with a clear mind, and adapt.","When the path ahead blurs, remember, hasty trades could shatter dreams. Stay keenly aware, minimize potential damage."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 51}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Touch Grass", "createdBy": "Cai Guo-Qiang x Kanon", "description": "It\'s not always about the hustle. Sometimes, it\'s about hitting the pause button. The code to cracking success isn\'t found in ceaseless motion, it\'s in the quiet corners of stillness too. The pros call this \'logging off\' or \'powering up the spirit.\'", "nodes": ["Touch grass with your toes, steady your stance. Recognize the halt before the hustle. Stay strong, stay true.","When your calves touch grass, you\'re in the zone. But if the big bosses press on without pausing, it\'s a drag.","Touching grass at your waist, you\'re too safe, too stiff. Sync with the rhythm around you to avoid trouble.","Feel the grass at your core, that\'s the spirit of stillness. You know when to hold \'em, when to fold \'em. No rash trades, no regrets.","Whisper to the wind, that\'s touching grass with your words. Know when to speak up, when to zip it. Pick your words wisely; they are your currency.","Be honest, be sincere in your stillness. It\'s your secret strength. Keep it real, keep it good for the best kind of win."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 52}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Proof of Work", "createdBy": "Cai Guo-Qiang x Kanon", "description": "With each hash computed, Proof of Work embodies the relentless grind of progress. Not a get-rich-quick scheme, but a testament to steady, consistent effort. The reward? A block added to your financial success.", "nodes": ["The fresh entrant might spark a meme frenzy, yet it\'s their persistence and the backing of their network that will keep their portfolio green.","The diligent trader, steadily accruing premiums, finds joy not in fleeting pumps but in the stable growth of their assets.","Trouble brews when trades are forced and partnerships sour. Stay true to your strategy, shrug off the FUD, and stand firm against market manipulators.","The calm hodler, like a node in the network, will always find a block to add to their chain.","Unwavering dedication to Proof of Work and the security it delivers guarantees the growth of wealth and the fulfillment of one\'s goals.","Principles and wisdom, shielded from the network\'s noise, set the foundation for a fortune that\'s robust and resilient."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 53}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Golden Arches", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Just like the hustle of McDonald\'s at lunchtime, crypto is a fast-paced, all-hands-on-deck environment. You might start as the newbie, flipping burgers and working those low-volume trades, but with resilience, clever strategy, and a dash of humility, you can rise through the ranks. Remember, even the best had to start somewhere. Stay grounded, harness team dynamics, and who knows? You might be running the joint someday.", "nodes": ["Crypto\'s your griddle, and you\'re flipping those first trades. Mutual support? That\'s your Szechuan sauce to good fortune.","Character and positivity are your patties and buns. They can turn any challenging trade into a tasty success.","Being the burger assembler isn\'t a demotion, it\'s an opportunity. You\'re making sure every layer is perfect; your cooperative contributions make a big difference.","Wait for the golden brown before you scoop those fries. Patience and careful planning are key to success.","True fulfillment? That\'s the authentic, well-made burger. Forget the fancy packaging; focus on the ingredients of integrity.","No one likes a fake cheeseburger. Serve up honesty and authenticity in all your connections."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 54}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Fat Tendies", "createdBy": "Cai Guo-Qiang x Kanon", "description": "As a crypto trader, you know that success comes with a side of caution. Remember, after every bull run, a bear is lurking. Enjoy your tendies but keep an eye on the dip. Don\'t get lost in the sauce of success; complacency can lead to a rug pull. When your bags are full, remember to give back to the community. A whale in isolation is just a target for hungry sharks.", "nodes": ["Find your tribe in the market, those who vibe with your strategy. Together, you can ride the bull and avoid the bear.","When your coin is mooning, don\'t forget about the potential dump. Stay transparent and honest; it\'s the ticket to long-term gains.","The peak of a pump can lead to the loss of a trading partner. But keep your cool, adapt, and the market will reward you.","In times of FUD, find your fellow hodlers. You\'ll weather the storm together and come out stronger.","Keep your ego in check and your wallet open. A generous trader is a magnet for success and good vibes.","Hoarding coins and isolating yourself? That\'s a one-way ticket to Rekt City. Remember, crypto is a community, not a one-man show."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 55}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Double Top", "createdBy": "Cai Guo-Qiang x Kanon", "description": "When the crypto market surges with an eye-popping rally, volatility is never far behind, making the climb to the moon a bit trickier. As the bullish fever subsides, it\'s crucial to dive into fresh ventures and kickstart new cycles. Doubling down on deflated coins is a one-way ticket to loss city. To stay in the green, you need a bird\'s-eye view of the macro landscape, not just snapshots of the day\'s top movers. The key to staying in the green is staying ahead of the curve by understanding the broader cycles of ups and downs.", "nodes": ["If you\'re busy chasing every meme coin that comes your way, you\'ll soon find your wallet in the red.","With a well-balanced portfolio, a stash of Bitcoin, and a reliable trading buddy, you\'re on the right track. Stay true to your strategy, and you\'ll weather the storm.","Stagnation and a brash attitude towards others can drain your wallet and tarnish your reputation. A reality check can keep adversity at bay.","Marooned in a bear market, even a treasure chest of new coins can\'t spark joy. Look for a deeper purpose in your journey.","Sharing precious alpha in rough seas can carve your name into the hall of fame. This is the recognition that comes from lighting the way in a storm.","Clinging to outdated strategies and letting ego call the shots can lead to the dreaded portfolio wipeout. Self-reflection is your best friend."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 56}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Trend is your Friend", "createdBy": "Cai Guo-Qiang x Kanon", "description": "The trend is your friend, or so they say. It\'s about sailing with the market currents, not against them. This isn\'t about subservience or weakness - it\'s about strategic humility, steady progress, and a soft power play in an otherwise volatile game. You\'re the tactician here, influencing the decisions without inciting resistance. But careful, a thoughtful warrior knows that over-humility can blur the lines between master and doormat. When you plot your next move, remember - reflect, act, reflect again.", "nodes": ["Indecision can be a tough beast to tame. Lock your sights, muster your willpower, and pull the trigger on your call.","Loyalty to your strategy is a golden ticket in this game. With sincerity at your helm, fortune\'s yours for the taking, no slip-ups attached.","Fake humility is a faulty strategy in this game. It\'s a down escalator in an upward race. Stick with sincerity and transparency - the secret sauce to real progress.","Discard the baggage of past trades. Stay laser-focused on your goals. That\'s your ticket to the winners\' circle.","Stay solid, stay true. Good fortune is a fan of the unswerving. Balanced actions clear the path for harmonious outcomes.","Beware, too much humility can undermine your confidence. Persist in this path, and you risk hitting a roadblock. Avoid becoming the underdog in your own game."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 57}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Cat Vibing", "createdBy": "Cai Guo-Qiang x Kanon", "description": "The cat, vibing to the rhythm of the Ievan Polkka, isn\'t just a meme, it\'s an emblem of tranquility and authenticity. Its dance doesn\'t seek virality or price pumps; it conveys the sincere joy and promise of crypto. The beat it moves to isn\'t made of flashy validations, but the transformative pulse of decentralization. Its groove is a call from the heart of the crypto community, inviting everyone to partake in the dance of progress. It\'s a reminder that success in this realm isn\'t about ostentation, but about fostering inward harmony and spreading joy with every step.", "nodes": ["The cat\'s gentle sway is rooted in inner peace; it\'s the kind of joy that echoes good fortune. The dance is genuine, untouched by hollow flattery, unclouded by doubt.","Sincerity is the foundation of the cat\'s dance. Trust the rhythm; it makes any regret vanish. The joy it brings us, it\'s the kind of luck you can\'t fake.","Seeking joy through empty gestures only leads to a harsh fall. A dance driven by flattery is a dance to the tune of misfortune.","Overthinking the dance, feeling uneasy in the groove, it\'s a signal to step back to steer away from darkness.","The cat at the top of the world needs to keep its eyes open. Sycophants lurk in the shadows, ready to mislead for their gain. Danger lies in trusting their purrs.","Induced joy may not have explicit fortune or misfortune, but beware the cat lured to dance to the wrong beat."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 58}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Correction", "createdBy": "Cai Guo-Qiang x Kanon", "description": "When the market signals a turbulent downturn, it\'s time to go against the tribal instinct to cheer the market on and embrace a correction. A shrewd leader with wisdom, foresight, and an uncanny connection to the market\'s pulse plays a crucial role in steering the community towards prosperity. Market corrections not only flush out speculative excesses and overextended positions but also lay the groundwork for resilient and healthy growth. Embrace the cleansing power of a correction and witness the dawn of renewed progress.", "nodes": ["Be swift in recognizing the market\'s call for a correction - act swiftly to secure your position and that of your community as the tide shifts.","Seize openings and shed your speculative shitcoin positions quickly to dissipate regrets.","Resist the greedy urge to make it all back. Don\'t lose sight of the needs of frens and fam.","Letting go of maxi and permabull biases, even if it draws tribal sneers, leads to exceptional good fortune.","When the top dogs make their move, you can bet it will shake the market. Use past gainz to keep your community afloat - no point surviving if your community is wiped out.","As the dust settles post-correction, we\'re left standing tall, ready to take on whatever comes next."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 59}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Quantitative Tightening", "createdBy": "Cai Guo-Qiang x Kanon", "description": "After a nasty correction comes the calm, and those of us left standing are now ready to join forces and crack on with our mission. But hold up! This ain\'t the time to be popping bubbles every night at the clerb - daddy Powell has hit the big red QT button. Doesn\'t mean we have to count and cling on to every last sat - going overboard\'s just going to ruin everyone\'s vibe. It\'s about being savvy with our post-storm stash. Nail the balance, and we can catch a lift on the next moon mission. Blow it, and you better strap in for some serious turbulence.", "nodes": ["This QT era calls for silent strides, not grand gestures. Crypto discourse should be subtle and trades, tighter.","Sitting on the sidelines ain\'t a strategy, it\'s a missed opportunity. Inaction during QT is a one-way ticket to Rekt City.","Missed the last pump to sell into? No point crying over spilled crypto. Grind on.","Seasoned veterans have seen this dance before. Follow their savvy steps to accept QT and the restrictions needed to make it through.","Embrace the QT period, making frugality your new best friend. Keep the hardware wallet tight, and the path to progress becomes clear. Help frens and fam do the same.","Don\'t overcompensate for QT. Too much restraint can leave you stuck in the mud while the market passes you by."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 60}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Diamond Core", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Here\'s the alpha. Diamond hands, they come from a diamond core. A diamond core is all about sincerity, authenticity and trustworthiness. Not about making noise and then going silent. It\'s about staying true, staying trusted, and building bridges with others. But remember, flexing your diamond core ain\'t the game. Overconfidence, boasting - that\'s a one-way ticket to Rektville.", "nodes": ["The true alpha isn\'t about catching waves - it\'s about keeping your diamond core intact through the dips and the rips, and letting it steer you well clear of shady moves. Stay true and your fortune will shine.","True networking isn\'t hobnobbing at conferences - it\'s discovering other diamond cores among the shill posts. Seeing through the noise, that\'s real connection.","The market\'s a beast, but the diamond core\'s about integrity, not taming bulls or bears. Be the same you, bull market or bear.","Crypto growth means knowing when to HODL, when to let go. Drop the fool\'s gold, keep the diamond core. That\'s progress.","Diamond cores shine brightest together. Mutual trust bridges tradfi and defi. We\'re all speaking crypto.","Boasting is noise. A true diamond core knows sincere humility and trustworthiness is the power move. Overconfidence is your one-way ticket to Rektville."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 61}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "Reducing Leverage", "createdBy": "Cai Guo-Qiang x Kanon", "description": "Leverage can be your best friend or your worst enemy. It\'s a tough balance to strike. Yeah, there are times when cranking up the leverage is the play. But right now it\'s about as safe as juggling dynamite. Overdoing it will leave you in the crypto gutter. So, instead, keep it low and slow. Stick to the smaller plays where a bit of overreach won\'t leave you rekt. Remember, it\'s not about being the hare or the tortoise, it\'s about being the one who crosses the finish line.", "nodes": ["Throw caution to the wind, and you\'ll find yourself in a world of hurt.","Know your limits in this game. You can\'t always hit the jackpot, but play your cards right, and you\'ll stay in the green.","This ain\'t the time to push the envelope. If you try to force a moonshot, you\'re likely to crash and burn.","Stay sharp, don\'t let emotions cloud your judgement. Stubbornness will only get you liquidated.","The winds of change are blowing, but the conditions aren\'t ripe. Patience, my friend.","Arrogance and lack of restraint will leave you making a generous donation to the BitMEX insurance fund."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 62}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "The Top", "createdBy": "Cai Guo-Qiang x Kanon", "description": "We\'ve all seen it: the sky-high peaks of the crypto game. It\'s like a 24/7 party where everyone\'s high on success. But the real players, the ones who stick around, they know that there\'s a comedown after every high. So, when you\'re at the top, don\'t let it get to your head. The smart cookies know that after the party comes the hangover. The descent tho isn\'t just the beginning of the end. It\'s the time to plan your next move.", "nodes": ["Sure, tread carefully. But let\'s be real, sometimes even the best defence can\'t fend off a market downturn. Shit happens, and that\'s no one\'s fault.","If you lost a chunk of your portfolio in a bad trade, don\'t go chasing after it like a dog after a car. Give it a week. You might be surprised at how things turn around.","Don\'t give small time chumps the time of day, even if they somehow add value. Keep your eyes on the prize and don\'t let distractions derail your ride to the top.","Get this in your head: the market ebbs and flows. Don\'t just ride the wave, prepare for the undertow.","Sincerity and truthfulness aren\'t just virtues, they\'re your weapons in this wild crypto world. Keep it real, read the room, and you\'re set for good fortune.","When you hit a rough patch, remember, success isn\'t linear. When you\'ve tasted the top, sliding into the bottom is not the end. It\'s the starting line for your next race."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 63}, {"trait_type": "revealed", "value": "true"}, ',
      '{"name": "The Bottom", "createdBy": "Cai Guo-Qiang x Kanon", "description": "You know that saying \'what goes up must come down\'? Well, we\'ve hit rock bottom. But don\'t sweat it. Bottoms aren\'t just for sitting; they\'re tomorrow\'s launching pads. You\'re stuck in a crypto-quake, the ground\'s shaking, and the bears are growling, but keep your eyes on the prize. This is the start of a new cycle. From chaos, you need to forge a new order. That\'s your mission. Roll those sleeves up, you\'ve got work to do.", "nodes": ["There\'s a sweet spot between recklessly diving in and cautiously dipping a toe. It takes guts to know your limits when you\'re staring at the bottom.","You\'re walking on a tightrope, and it feels like the wind is against you. But stand tall, keep your cool, and press on. Fortune smiles on the steadfast.","Pushing forward feels like walking into a hurricane, but doing nothing? That\'s like sinking in quicksand. Stay on your toes. Scared money doesn\'t make money.","Before you hit the jackpot, you\'re going to need to dig deep. Rally your spirit, summon your strength. The journey to the top is a marathon, not a sprint.","In this game, the big winners are the genuine players. Be sincere, be honest, be humble. Even in the darkest hours, these qualities shine the brightest.","Understand this: after every night, the sun will rise. The bottom isn\'t a pit, it\'s a trampoline. So take a leap of faith, enjoy the ride and keep your eyes on the prize."], "attributes": [{"display_type":"number", "trait_type": "fortune_number", "value": 64}, {"trait_type": "revealed", "value": "true"}, '
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
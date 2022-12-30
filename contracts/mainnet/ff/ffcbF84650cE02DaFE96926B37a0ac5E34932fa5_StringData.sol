// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
    Extra XEN quotes:

    "When you realize nothing is lacking, the whole world belongs to you." - Lao Tzu
    "Each morning, we are born again. What we do today is what matters most." - Buddha
    "If you are depressed, you are living in the past." - Lao Tzu
    "In true dialogue, both sides are willing to change." - Thich Nhat Hanh
    "The spirit of the individual is determined by his domination thought habits." - Bruce Lee
    "Be the path. Do not seek it." - Yara Tschallener
    "Bow to no one but your own divinity." - Satya
    "With insight there is hope for awareness, and with awareness there can be change." - Tom Kenyon
    "The opposite of depression isn't happiness, it is purpose." - Derek Sivers
    "If you can't, you must." - Tony Robbins
    “When you are grateful, fear disappears and abundance appears.” - Lao Tzu
    “It is in your moments of decision that your destiny is shaped.” - Tony Robbins
    "Surmounting difficulty is the crucible that forms character." - Tony Robbins
    "Three things cannot be long hidden: the sun, the moon, and the truth." - Buddha
    "What you are is what you have been. What you’ll be is what you do now." - Buddha
    "The best way to take care of our future is to take care of the present moment." - Thich Nhat Hanh
*/

/**
   @dev  a library to supply a XEN string data based on params
*/
library StringData {
    uint256 public constant QUOTES_COUNT = 12;
    uint256 public constant QUOTE_LENGTH = 66;
    bytes public constant QUOTES =
        bytes(
            '"If you realize you have enough, you are truly rich." - Lao Tzu   '
            '"The real meditation is how you live your life." - Jon Kabat-Zinn '
            '"To know that you do not know is the best." - Lao Tzu             '
            '"An over-sharpened sword cannot last long." - Lao Tzu             '
            '"When you accept yourself, the whole world accepts you." - Lao Tzu'
            '"Music in the soul can be heard by the universe." - Lao Tzu       '
            '"As soon as you have made a thought, laugh at it." - Lao Tzu      '
            '"The further one goes, the less one knows." - Lao Tzu             '
            '"Stop thinking, and end your problems." - Lao Tzu                 '
            '"Reliability is the foundation of commitment." - Unknown          '
            '"Your past does not equal your future." - Tony Robbins            '
            '"Be the path. Do not seek it." - Yara Tschallener                 '
        );
    uint256 public constant CLASSES_COUNT = 14;
    uint256 public constant CLASSES_NAME_LENGTH = 10;
    bytes public constant CLASSES =
        bytes(
            "Ruby      "
            "Opal      "
            "Topaz     "
            "Emerald   "
            "Aquamarine"
            "Sapphire  "
            "Amethyst  "
            "Xenturion "
            "Limited   "
            "Rare      "
            "Epic      "
            "Legendary "
            "Exotic    "
            "Xunicorn  "
        );

    /**
        @dev    Solidity doesn't yet support slicing of byte arrays anywhere outside of calldata,
                therefore we make a hack by supplying our local constant packed string array as calldata
    */
    function getQuote(bytes calldata quotes, uint256 index) external pure returns (string memory) {
        if (index > QUOTES_COUNT - 1) return string(quotes[0:QUOTE_LENGTH]);
        return string(quotes[index * QUOTE_LENGTH:(index + 1) * QUOTE_LENGTH]);
    }

    function getClassName(bytes calldata names, uint256 index) external pure returns (string memory) {
        if (index < CLASSES_COUNT) return string(names[index * CLASSES_NAME_LENGTH:(index + 1) * CLASSES_NAME_LENGTH]);
        return "";
    }
}
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract RCPTFont {
  // based off the very excellent Noto Sans Mono font

  /*
  
    This Font Software is licensed under the SIL Open Font License, Version 1.1.
    This license is copied below, and is also available with a FAQ at:
    http://scripts.sil.org/OFL


    -----------------------------------------------------------
    SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
    -----------------------------------------------------------

    PREAMBLE
    The goals of the Open Font License (OFL) are to stimulate worldwide
    development of collaborative font projects, to support the font creation
    efforts of academic and linguistic communities, and to provide a free and
    open framework in which fonts may be shared and improved in partnership
    with others.

    The OFL allows the licensed fonts to be used, studied, modified and
    redistributed freely as long as they are not sold by themselves. The
    fonts, including any derivative works, can be bundled, embedded, 
    redistributed and/or sold with any software provided that any reserved
    names are not used by derivative works. The fonts and derivatives,
    however, cannot be released under any other type of license. The
    requirement for fonts to remain under this license does not apply
    to any document created using the fonts or their derivatives.

    DEFINITIONS
    "Font Software" refers to the set of files released by the Copyright
    Holder(s) under this license and clearly marked as such. This may
    include source files, build scripts and documentation.

    "Reserved Font Name" refers to any names specified as such after the
    copyright statement(s).

    "Original Version" refers to the collection of Font Software components as
    distributed by the Copyright Holder(s).

    "Modified Version" refers to any derivative made by adding to, deleting,
    or substituting -- in part or in whole -- any of the components of the
    Original Version, by changing formats or by porting the Font Software to a
    new environment.

    "Author" refers to any designer, engineer, programmer, technical
    writer or other person who contributed to the Font Software.

    PERMISSION & CONDITIONS
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of the Font Software, to use, study, copy, merge, embed, modify,
    redistribute, and sell modified and unmodified copies of the Font
    Software, subject to the following conditions:

    1) Neither the Font Software nor any of its individual components,
    in Original or Modified Versions, may be sold by itself.

    2) Original or Modified Versions of the Font Software may be bundled,
    redistributed and/or sold with any software, provided that each copy
    contains the above copyright notice and this license. These can be
    included either as stand-alone text files, human-readable headers or
    in the appropriate machine-readable metadata fields within text or
    binary files as long as those fields can be easily viewed by the user.

    3) No Modified Version of the Font Software may use the Reserved Font
    Name(s) unless explicit written permission is granted by the corresponding
    Copyright Holder. This restriction only applies to the primary font name as
    presented to the users.

    4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
    Software shall not be used to promote, endorse or advertise any
    Modified Version, except to acknowledge the contribution(s) of the
    Copyright Holder(s) and the Author(s) or with their explicit written
    permission.

    5) The Font Software, modified or unmodified, in part or in whole,
    must be distributed entirely under this license, and must not be
    distributed under any other license. The requirement for fonts to
    remain under this license does not apply to any document created
    using the Font Software.

    TERMINATION
    This license becomes null and void if any of the above conditions are
    not met.

    DISCLAIMER
    THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
    OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
    DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
    OTHER DEALINGS IN THE FONT SOFTWARE.
  
  */

  string public constant font =
    "data:application/font-woff2;charset=utf-8;base64,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";
}
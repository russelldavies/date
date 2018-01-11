module Tests exposing (..)

import Date.RataDie as Date exposing (Month(..), Unit(..), Weekday(..))
import Expect exposing (Expectation)
import Test exposing (Test, describe, test)


type alias Date =
    Int


test_CalendarDate : Test
test_CalendarDate =
    describe "CalendarDate"
        [ describe "CalendarDate and Date are are isomorphic"
            (List.concat
                [ List.range 1897 1905
                , List.range 1997 2025
                ]
                |> List.concatMap calendarDatesInYear
                |> List.map
                    (\calendarDate ->
                        test (toString calendarDate) <|
                            \() -> expectIsomorphism fromCalendarDate Date.toCalendarDate calendarDate
                    )
            )
        , test "fromCalendarDate produces a contiguous list of integers from a contiguous list of calendar dates" <|
            \() ->
                List.range 1997 2025
                    |> List.concatMap (calendarDatesInYear >> List.map fromCalendarDate)
                    |> Expect.equal (List.range (Date.fromCalendarDate 1997 Jan 1) (Date.fromCalendarDate 2025 Dec 31))
        ]


test_WeekDate : Test
test_WeekDate =
    describe "WeekDate"
        [ describe "WeekDate and Date are isomorphic"
            (List.range 1997 2025
                |> List.concatMap calendarDatesInYear
                |> List.map
                    (\calendarDate ->
                        test (toString calendarDate) <|
                            \() -> expectIsomorphism Date.toWeekDate fromWeekDate (fromCalendarDate calendarDate)
                    )
            )
        , describe "toWeekDate produces results that match samples"
            ([ ( CalendarDate 2005 Jan 1, WeekDate 2004 53 Sat )
             , ( CalendarDate 2005 Jan 2, WeekDate 2004 53 Sun )
             , ( CalendarDate 2005 Dec 31, WeekDate 2005 52 Sat )
             , ( CalendarDate 2007 Jan 1, WeekDate 2007 1 Mon )
             , ( CalendarDate 2007 Dec 30, WeekDate 2007 52 Sun )
             , ( CalendarDate 2007 Dec 31, WeekDate 2008 1 Mon )
             , ( CalendarDate 2008 Jan 1, WeekDate 2008 1 Tue )
             , ( CalendarDate 2008 Dec 28, WeekDate 2008 52 Sun )
             , ( CalendarDate 2008 Dec 29, WeekDate 2009 1 Mon )
             , ( CalendarDate 2008 Dec 30, WeekDate 2009 1 Tue )
             , ( CalendarDate 2008 Dec 31, WeekDate 2009 1 Wed )
             , ( CalendarDate 2009 Jan 1, WeekDate 2009 1 Thu )
             , ( CalendarDate 2009 Dec 31, WeekDate 2009 53 Thu )
             , ( CalendarDate 2010 Jan 1, WeekDate 2009 53 Fri )
             , ( CalendarDate 2010 Jan 2, WeekDate 2009 53 Sat )
             , ( CalendarDate 2010 Jan 3, WeekDate 2009 53 Sun )
             ]
                |> List.map
                    (\( calendarDate, weekDate ) ->
                        test (toString calendarDate) <|
                            \() -> fromCalendarDate calendarDate |> Date.toWeekDate |> Expect.equal weekDate
                    )
            )
        ]


test_toFormattedString : Test
test_toFormattedString =
    let
        testDateToFormattedString : Date -> ( String, String ) -> Test
        testDateToFormattedString date ( pattern, expected ) =
            test ("\"" ++ pattern ++ "\" " ++ toString date) <|
                \() -> date |> Date.toFormattedString pattern |> Expect.equal expected
    in
    describe "toFormattedString"
        [ describe "replaces supported character patterns" <|
            List.map
                (testDateToFormattedString (Date.fromCalendarDate 2001 Jan 2))
                [ ( "y", "2001" )
                , ( "yy", "01" )
                , ( "yyy", "2001" )
                , ( "yyyy", "2001" )
                , ( "yyyyy", "02001" )
                , ( "Y", "2001" )
                , ( "YY", "01" )
                , ( "YYY", "2001" )
                , ( "YYYY", "2001" )
                , ( "YYYYY", "02001" )
                , ( "Q", "1" )
                , ( "QQ", "1" )
                , ( "QQQ", "Q1" )
                , ( "QQQQ", "1st" )
                , ( "QQQQQ", "1" )
                , ( "QQQQQQ", "" )
                , ( "M", "1" )
                , ( "MM", "01" )
                , ( "MMM", "Jan" )
                , ( "MMMM", "January" )
                , ( "MMMMM", "J" )
                , ( "MMMMMM", "" )
                , ( "w", "1" )
                , ( "ww", "01" )
                , ( "www", "" )
                , ( "d", "2" )
                , ( "dd", "02" )
                , ( "ddd", "2nd" )
                , ( "dddd", "" )
                , ( "D", "2" )
                , ( "DD", "02" )
                , ( "DDD", "002" )
                , ( "DDDD", "" )
                , ( "E", "Tue" )
                , ( "EE", "Tue" )
                , ( "EEE", "Tue" )
                , ( "EEEE", "Tuesday" )
                , ( "EEEEE", "T" )
                , ( "EEEEEE", "Tu" )
                , ( "EEEEEEE", "" )
                , ( "e", "2" )
                , ( "ee", "2" )
                , ( "eee", "Tue" )
                , ( "eeee", "Tuesday" )
                , ( "eeeee", "T" )
                , ( "eeeeee", "Tu" )
                , ( "eeeeeee", "" )
                ]
        , describe "ignores unsupported character patterns" <|
            List.map
                (testDateToFormattedString (Date.fromCalendarDate 2008 Dec 31))
                [ ( "ABCFGHIJKLNOPRSTUVWXZabcfghijklmnopqrstuvxz", "ABCFGHIJKLNOPRSTUVWXZabcfghijklmnopqrstuvxz" )
                , ( "0123456789", "0123456789" )
                ]
        , describe "handles escaped characters and escaped escape characters" <|
            List.map
                (testDateToFormattedString (Date.fromCalendarDate 2001 Jan 2))
                [ ( "'yYQMwdDEe'", "yYQMwdDEe" )
                , ( "''' '' ''' ''", "' ' ' '" )
                , ( "'yyyy:' yyyy", "yyyy: 2001" )
                ]
        , describe "formats day ordinals" <|
            List.map
                (\( n, string ) ->
                    testDateToFormattedString (Date.fromCalendarDate 2001 Jan n) ( "ddd", string )
                )
                [ ( 1, "1st" )
                , ( 2, "2nd" )
                , ( 3, "3rd" )
                , ( 4, "4th" )
                , ( 5, "5th" )
                , ( 6, "6th" )
                , ( 7, "7th" )
                , ( 8, "8th" )
                , ( 9, "9th" )
                , ( 10, "10th" )
                , ( 11, "11th" )
                , ( 12, "12th" )
                , ( 13, "13th" )
                , ( 14, "14th" )
                , ( 15, "15th" )
                , ( 16, "16th" )
                , ( 17, "17th" )
                , ( 18, "18th" )
                , ( 19, "19th" )
                , ( 20, "20th" )
                , ( 21, "21st" )
                , ( 22, "22nd" )
                , ( 23, "23rd" )
                , ( 24, "24th" )
                , ( 25, "25th" )
                , ( 26, "26th" )
                , ( 27, "27th" )
                , ( 28, "28th" )
                , ( 29, "29th" )
                , ( 30, "30th" )
                , ( 31, "31st" )
                ]
        , describe "formats with sample patterns as expected" <|
            List.map
                (testDateToFormattedString (Date.fromCalendarDate 2008 Dec 31))
                [ ( "yyyy-MM-dd", "2008-12-31" )
                , ( "yyyy-DDD", "2008-366" )
                , ( "YYYY-'W'ww-e", "2009-W01-3" )
                , ( "M/d/y", "12/31/2008" )
                , ( "''yy", "'08" )
                ]
        ]


test_add : Test
test_add =
    let
        toTest : ( Int, Month, Int ) -> Int -> Unit -> ( Int, Month, Int ) -> Test
        toTest ( y1, m1, d1 ) n unit (( y2, m2, d2 ) as expected) =
            test (toString ( y1, m1, d1 ) ++ " + " ++ toString n ++ " " ++ toString unit ++ " => " ++ toString expected) <|
                \() ->
                    Date.fromCalendarDate y1 m1 d1 |> Date.add unit n |> Expect.equal (Date.fromCalendarDate y2 m2 d2)
    in
    describe "add"
        [ describe "add 0 x == x" <|
            List.map
                (\unit -> toTest ( 2000, Jan, 1 ) 0 unit ( 2000, Jan, 1 ))
                [ Years, Months, Weeks, Days ]
        , describe "adding positive numbers works as expected"
            [ toTest ( 2000, Jan, 1 ) 2 Years ( 2002, Jan, 1 )
            , toTest ( 2000, Jan, 1 ) 2 Months ( 2000, Mar, 1 )
            , toTest ( 2000, Jan, 1 ) 2 Weeks ( 2000, Jan, 15 )
            , toTest ( 2000, Jan, 1 ) 2 Days ( 2000, Jan, 3 )
            , toTest ( 2000, Jan, 1 ) 18 Years ( 2018, Jan, 1 )
            , toTest ( 2000, Jan, 1 ) 18 Months ( 2001, Jul, 1 )
            , toTest ( 2000, Jan, 1 ) 18 Weeks ( 2000, May, 6 )
            , toTest ( 2000, Jan, 1 ) 36 Days ( 2000, Feb, 6 )
            ]
        , describe "adding negative numbers works as expected"
            [ toTest ( 2000, Jan, 1 ) -2 Years ( 1998, Jan, 1 )
            , toTest ( 2000, Jan, 1 ) -2 Months ( 1999, Nov, 1 )
            , toTest ( 2000, Jan, 1 ) -2 Weeks ( 1999, Dec, 18 )
            , toTest ( 2000, Jan, 1 ) -2 Days ( 1999, Dec, 30 )
            , toTest ( 2000, Jan, 1 ) -18 Years ( 1982, Jan, 1 )
            , toTest ( 2000, Jan, 1 ) -18 Months ( 1998, Jul, 1 )
            , toTest ( 2000, Jan, 1 ) -18 Weeks ( 1999, Aug, 28 )
            , toTest ( 2000, Jan, 1 ) -18 Days ( 1999, Dec, 14 )
            ]
        , describe "adding Years from a leap day clamps overflow to the end of February"
            [ toTest ( 2000, Feb, 29 ) 1 Years ( 2001, Feb, 28 )
            , toTest ( 2000, Feb, 29 ) 4 Years ( 2004, Feb, 29 )
            ]
        , describe "adding Months clamps overflow to the end of a short month"
            [ toTest ( 2000, Jan, 31 ) 1 Months ( 2000, Feb, 29 )
            , toTest ( 2000, Jan, 31 ) 2 Months ( 2000, Mar, 31 )
            , toTest ( 2000, Jan, 31 ) 3 Months ( 2000, Apr, 30 )
            , toTest ( 2000, Jan, 31 ) 13 Months ( 2001, Feb, 28 )
            ]
        ]


test_diff : Test
test_diff =
    let
        toTest : ( Int, Month, Int ) -> ( Int, Month, Int ) -> Int -> Unit -> Test
        toTest ( y1, m1, d1 ) ( y2, m2, d2 ) expected unit =
            test (toString ( y2, m2, d2 ) ++ " - " ++ toString ( y1, m1, d1 ) ++ " => " ++ toString expected ++ " " ++ toString unit) <|
                \() ->
                    Date.diff unit (Date.fromCalendarDate y1 m1 d1) (Date.fromCalendarDate y2 m2 d2) |> Expect.equal expected
    in
    describe "diff"
        [ describe "diff x x == 0" <|
            List.map
                (\unit -> toTest ( 2000, Jan, 1 ) ( 2000, Jan, 1 ) 0 unit)
                [ Years, Months, Weeks, Days ]
        , describe "diff x y == -(diff y x)" <|
            let
                ( x, y ) =
                    ( Date.fromCalendarDate 2000 Jan 1, Date.fromCalendarDate 2017 Sep 28 )
            in
            List.map
                (\unit -> test (toString unit) <| \() -> Date.diff unit x y |> Expect.equal (negate (Date.diff unit y x)))
                [ Years, Months, Weeks, Days ]
        , describe "`diff earlier later` results in positive numbers"
            [ toTest ( 2000, Jan, 1 ) ( 2002, Jan, 1 ) 2 Years
            , toTest ( 2000, Jan, 1 ) ( 2000, Mar, 1 ) 2 Months
            , toTest ( 2000, Jan, 1 ) ( 2000, Jan, 15 ) 2 Weeks
            , toTest ( 2000, Jan, 1 ) ( 2000, Jan, 3 ) 2 Days
            , toTest ( 2000, Jan, 1 ) ( 2018, Jan, 1 ) 18 Years
            , toTest ( 2000, Jan, 1 ) ( 2001, Jul, 1 ) 18 Months
            , toTest ( 2000, Jan, 1 ) ( 2000, May, 6 ) 18 Weeks
            , toTest ( 2000, Jan, 1 ) ( 2000, Feb, 6 ) 36 Days
            ]
        , describe "`diff later earlier` results in negative numbers"
            [ toTest ( 2000, Jan, 1 ) ( 1998, Jan, 1 ) -2 Years
            , toTest ( 2000, Jan, 1 ) ( 1999, Nov, 1 ) -2 Months
            , toTest ( 2000, Jan, 1 ) ( 1999, Dec, 18 ) -2 Weeks
            , toTest ( 2000, Jan, 1 ) ( 1999, Dec, 30 ) -2 Days
            , toTest ( 2000, Jan, 1 ) ( 1982, Jan, 1 ) -18 Years
            , toTest ( 2000, Jan, 1 ) ( 1998, Jul, 1 ) -18 Months
            , toTest ( 2000, Jan, 1 ) ( 1999, Aug, 28 ) -18 Weeks
            , toTest ( 2000, Jan, 1 ) ( 1999, Dec, 14 ) -18 Days
            ]
        , describe "diffing Years returns a number of whole years as determined by calendar date (anniversary)"
            [ toTest ( 2000, Feb, 29 ) ( 2001, Feb, 28 ) 0 Years
            , toTest ( 2000, Feb, 29 ) ( 2004, Feb, 29 ) 4 Years
            ]
        , describe "diffing Months returns a number of whole months as determined by calendar date"
            [ toTest ( 2000, Jan, 31 ) ( 2000, Feb, 29 ) 0 Months
            , toTest ( 2000, Jan, 31 ) ( 2000, Mar, 31 ) 2 Months
            , toTest ( 2000, Jan, 31 ) ( 2000, Apr, 30 ) 2 Months
            , toTest ( 2000, Jan, 31 ) ( 2001, Feb, 28 ) 12 Months
            ]
        ]



-- helpers


type alias CalendarDate =
    { year : Int, month : Month, day : Int }


fromCalendarDate : CalendarDate -> Date
fromCalendarDate { year, month, day } =
    Date.fromCalendarDate year month day


calendarDatesInYear : Int -> List CalendarDate
calendarDatesInYear y =
    [ Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec ]
        |> List.concatMap
            (\m -> List.range 1 (daysInMonth y m) |> List.map (CalendarDate y m))


isLeapYear : Int -> Bool
isLeapYear y =
    y % 4 == 0 && y % 100 /= 0 || y % 400 == 0


daysInMonth : Int -> Month -> Int
daysInMonth y m =
    case m of
        Jan ->
            31

        Feb ->
            if isLeapYear y then
                29
            else
                28

        Mar ->
            31

        Apr ->
            30

        May ->
            31

        Jun ->
            30

        Jul ->
            31

        Aug ->
            31

        Sep ->
            30

        Oct ->
            31

        Nov ->
            30

        Dec ->
            31


type alias WeekDate =
    { weekYear : Int, week : Int, weekday : Weekday }


fromWeekDate : WeekDate -> Date
fromWeekDate { weekYear, week, weekday } =
    Date.fromWeekDate weekYear week weekday



--


expectIsomorphism : (x -> y) -> (y -> x) -> x -> Expectation
expectIsomorphism xToY yToX x =
    x |> xToY |> yToX |> Expect.equal x
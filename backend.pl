#!/usr/bin/env perl

use strict;
use warnings;
use Mojolicious::Lite;

get '/' => sub {
    my $self = shift;
    $self->render( 'home' );
};

get '/js' => sub {
    my $self = shift;
    $self->render( 'js' );
};

get '/current/score' => sub {
    my $self = shift;
    my $score = $self->param( 'score' );
    $self->render( text => $score + 1 );
};

app->start;

__DATA__

@@ home.html.ep


<!DOCTYPE html>
<head>
    <script src="/jquery_1_8_2_min.js"></script>
    <script src="/jquery_cookie.js"></script>
    <script type="text/javascript" src="/crafty.js"></script>
    <script type="text/javascript" src="/js"></script>
    <title>My Crafty Game</title>
    <style>
    body, html { margin:0; padding: 0; overflow:hidden; font-family:Arial; font-size:20px }
    #cr-stage { border:2px solid black; margin:5px auto; color:white }
    </style>
</head>
<body>
</body>
</html>

@@ js.html.ep


$(document).ready(function() {
    Crafty.init( 600, 400 ).canvas.init();

    jQuery.cookie("high_score", 0);

    function create_paddle (x, y, speed) {
        var paddle = Crafty.e("2D, Canvas, Color, Player, Multiway")
            .attr({w: 10, h: 75, x: x, y: y})
            .color("white")
            .multiway(speed, {
                W: 270, S: 90
            });
        return paddle;
    }

    function create_rect (w, h, x, y, color) {
        var rect = Crafty.e("2D, Canvas, Color")
            .attr({w: w, h: h, x: x, y: y})
            .color(color);
        return rect;
    }

    function create_text (text, x, y) {
        var text = Crafty.e("2D, DOM, Text")
            .attr({ x: x, y: y })
            .text(text);
        return text;
    }

    function create_ball () {
        var ball = Crafty.e("2D, Canvas, Color")
            .attr({w: 20, h: 20, x: 300, y: 200})
            .color("white");
        return ball;
    }

    function bounce_right ( object, collide ) {
        if ( object.y >= collide.y && object.y <= collide.y+collide.h && object.x <= collide.x+collide.w ) {
            return -1;
        }
        else {
            return 1;
        }
    }

    function bounce_left ( object, collide ) {
        if ( object.y >= collide.y && object.y <= collide.y+collide.h && object.x+object.w >= collide.x ) {
            return -1;
        }
        else { return 1; }
    }

    function bounce_walls ( object ) {
        if ( object.y <= 100 || object.y >= 375 ) { return -1; }
        else { return 1; };
    }

    function respawn () {
        var respawn_point = Math.floor((Math.random()*100)+200);
        return respawn_point;
    }

    function lose ( object ) {
        if ( object.x <= 0 || object.x >= 600 ) {
            object.x = respawn();
            object.y = respawn();
            return 1;
        }
    }

    function paddle_control ( paddle ) {
        if ( paddle.y <= 100 ) {
            paddle.y = 100;
        }
        else if( paddle.y >= 300 ) {
            paddle.y = 300;
        };
    }

    function local_score ( score ) {
        jQuery.get('/current/score?score='+score,
        function(response) {
            return response;
        });
    }

    function high_score ( score ) {
        var highest_standing = jQuery.cookie("high_score");
        if ( highest_standing == 'null' || highest_standing < score ) {
            jQuery.cookie("high_score", score);
        }
    }

    function difficulty () {
        var diff = prompt('Difficulty: ( type "easy", "medium", or "hard")');
        if ( diff == 'easy' || diff == 'medium' || diff == 'hard' ) {
            return diff;
        }
        else {
            difficulty();
        }
    }

    function game_over ( life ) {
        if ( life == 0 ) {
            window.location.reload();
        }
    }

    function center_line () {
        create_rect( 20, 50, 290, 85, "white" );
        create_rect( 20, 50, 290, 135, "black" );
        create_rect( 20, 50, 290, 185, "white" );
        create_rect( 20, 50, 290, 235, "black" );
        create_rect( 20, 50, 290, 285, "white" );
        create_rect( 20, 50, 290, 335, "black" );
        create_rect( 20, 50, 290, 385, "white" );
    }

    Crafty.scene("loading", function() {
        setTimeout(function() {
            Crafty.scene("main");
        }, 1000);

    Crafty.background("black");
    Crafty.e("2D, DOM, Text").attr({w: 640, h: 20 , x: 0, y: 120})
        .text("LEVEL 1")
        .css({"text-align": "center"});
    });

    Crafty.scene("main", function() {
        Crafty.background("black");
        var paddle_speed;
        var ball_speed;
        var diff_level = difficulty();

        if ( diff_level == 'easy' ) {
            paddle_speed = 7;
            ball_speed = 1;
        }
        else if ( diff_level == 'medium' ) {
            paddle_speed = 6;
            ball_speed = 1.5;
        }
        else if ( diff_level == 'hard' ) {
            paddle_speed = 5;
            ball_speed = 2;
        }

        jQuery('body').click(function() {
            alert(jQuery.cookie("high_score"));
        });

        var player = create_paddle( 25, 200, paddle_speed );
        var enemy = create_paddle( 575, 200, paddle_speed );
        var upper_line = create_rect( 600, 20, 0, 80, "white" );
        center_line();
        var ball_xv = ball_speed;
        var ball_yv = ball_speed;

        var old_score = 0;
        var current_score = create_text(0, 0, 0);

        var score_cookie = jQuery.cookie("high_score");
        var new_high_score = create_text(score_cookie, 500, 0);

        var lifes = 5;
        var life_count = create_text(lifes, 295, 0);

        var ball = create_ball();
        setInterval(function() {
            ball.attr({x: ball.x-ball_xv, y: ball.y-ball_yv});
            if (bounce_right(ball, player) == -1) { old_score += 1 }
            if (bounce_left(ball, enemy) == -1) { old_score += 1 }
            if (lose( ball ) == 1) {
                high_score(old_score);
                lifes -= 1;
                old_score = 0; }
            ball_xv *= bounce_right (
                ball,
                player
            );
            ball_xv *= bounce_left (
                ball,
                enemy
            );
            ball_yv *= bounce_walls ( ball );
            paddle_control( player );
            paddle_control( enemy );
            lose( ball );
            life_count.text(lifes);
            current_score.text("Current Score: "+old_score);
            score_cookie = jQuery.cookie("high_score");
            new_high_score.text("High Score: "+score_cookie);
            game_over( lifes );
        }, 5);
    });

    Crafty.scene("loading");
});

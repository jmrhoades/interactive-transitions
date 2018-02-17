// https://www.shadertoy.com/view/4s33zn

// TRY TO GET THIS ONE TO WORK, IT"S PERFECT

void main()
{
    vec2  i      =    gl_FragCoord.xy;
    float f      =    .5;
    float r      =    size.x;
    float t      =    u_time * .03;
    float c      =    cos( t );
    float s      =    sin( t );
    i            =    ( i / r - f ) * mat2( c, s, -s, c );
    vec3 d       =    floor( f * r * vec3( i, f ) );
    gl_FragColor =    vec4( 1. / ( f + exp( 2e2 * fract( sin( dot( d * sin( d.x ) + f, vec3( 13, 78.2, 57.1 ) ) ) * 1e5 ) ) ) );
}

/*
void mainImage( out vec4 o, vec2 i )
{
    float f        =    .5,
    r            =    iResolution.x,
    t            =    iDate.w * .1,
    c            =    cos( t ),
    s            =    sin( t );
    i            =    ( i / r - f ) * mat2( c, s, -s, c );
    vec3 d        =    floor( f * r * vec3( i, f ) );
    o             =    vec4( 1. / ( f + exp( 2e2 * fract( sin( dot( d * sin( d.x ) + f, vec3( 13, 78.2, 57.1 ) ) ) * 1e5 ) ) ) );
}
*/

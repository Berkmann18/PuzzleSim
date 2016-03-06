void setup(){
  size(600, 500);
  smooth();
  //noLoop();
  background(255);
  surface.setTitle("N-puzzle Simulator"); 
  Hpzl.init();
  Fpzl.init();
  Tpzl.init();
}

pzl Hpzl = new pzl(9), Fpzl = new pzl(16), Tpzl = new pzl(25);
color winBgClr = color(255);
boolean debug = false, timedMode = false;
int min=0, s=0, ms=0;
void draw(){
  background(winBgClr);
  //Hpzl.disp();
  //Fpzl.disp();
  //Tpzl.disp();
  Hpzl.draw();
  textSize(24);
  if(timedMode) text(min+":"+s+"."+ms, 50, 20);
  if(Hpzl.isSolved() && s!=0 && ms!=0) timedMode = false; 
}

class pzl{//N-puzzle of size nxn
  int w, h, nbTiles = 9, tiles[][] = {{1, 2, 3}, {4, 5, 6}, {7, 8, 0}}, tileSize = 80;
  color borderClr = color(0), txtClr = color(0), tileClr = color(255, 0, 0), bgClr = color(255), solvedTileClr = color(0, 255, 0);
  String style = "fringe";//{"mono", "state", "l2l", "fringe"};
  pzl(int nb){
    nbTiles = nb;
    w = (int) sqrt(nbTiles)*tileSize;
    h = w;
  }
  void init(){
    tiles = new int[(int)sqrt(nbTiles)][(int)sqrt(nbTiles)];
    int n = 1;
    for(int i=0; i<tiles.length; i++){
      for(int j=0; j<tiles.length; j++) tiles[i][j] = n++;
    }
    tiles[(int)sqrt(nbTiles)-1][(int)sqrt(nbTiles)-1] = 0;
  }
  void draw(){
     stroke(borderClr);
     fill(bgClr);
     textSize(41/30*tileSize);
     float surplus = (nbTiles>9)? 1.5: 1;
     int x = 50, y = 50, ic = 48*tileSize/30, n = 1;
     float spg = 2.8;
     //rect(x+ic-3, int(y+ic/4), w+ic, h+ic);
     for(int i=0; i<tiles.length; i++){
       y+=ic;
       for(int j=0; j<tiles.length; j++){
         if((surplus==1 && tiles[i][j]!=0) || (surplus>1 && tiles[i][j]>=10)){
           if(style.equals("mono")) fill(tileClr);
           else if(style.equals("state")){
             if(tiles[i][j]==n) fill(solvedTileClr);
             else fill(tileClr);
           }else if(style.equals("l2l") || style.equals("lbl")){
             if(tiles[i][j]>=1 && tiles[i][j]<=3) fill(255, 0, 0);
             if(tiles[i][j]>=4 && tiles[i][j]<=6) fill(0, 255, 0);
             if(tiles[i][j]>=7 && tiles[i][j]<9) fill(0, 0, 255);
           }else if(style.equals("fringe")){
             if((tiles[i][j]>=1 && tiles[i][j]<=3) || tiles[i][j]==4 || tiles[i][j]==7) fill(255, 0, 0);
             if(tiles[i][j]==5 || tiles[i][j]==6 || tiles[i][j]==8) fill(0, 255, 0);
           }
           n++;
           rect(x+ic*28.75/37.5, y-ic/2-ic/3.5+ic/20/*(1.5/7+1/20)*/, tileSize+ic/spg, tileSize+ic/spg);
           fill(txtClr);
           text(tiles[i][j], x+=ic+1, y);
         }else if(tiles[i][j]==0) text(" ", x+=ic+2, y);
         else{
           fill(tileClr);
           rect(x+ic, y/*-ic/2-ic/10*/, tileSize/*+ic/10*/, tileSize/*+ic/10*/);
           fill(txtClr);
           text(tiles[i][j], x+=ic+2, y);
         }
       }
       x = 50;
     }
  }
  void disp(){
     float surplus = (nbTiles>9)? 1.5: 1;
     for(int i=0; i<tiles.length; i++){
       for(int k=0; k<=tiles.length*2*surplus; k++) print("-");
       println();
       for(int j=0; j<tiles.length; j++){
         if(surplus==1 || (surplus>1 && tiles[i][j]>=10)) print("|"+((tiles[i][j]==0)?" ":tiles[i][j]));
         else print("| "+((tiles[i][j]==0)?" ":tiles[i][j]));
       }
       println("|");
     }
     for(int k=0; k<=tiles.length*2*surplus; k++) print("-");
     println();
  }
  void move(char mv){
    int[] emptyTile = lookfor(0, tiles);
    try{
      switch(mv){
        case 'U': swp(emptyTile[0]+1, emptyTile[1], emptyTile[0], emptyTile[1]);break;
        case 'R': swp(emptyTile[0], emptyTile[1]-1, emptyTile[0], emptyTile[1]);break;
        case 'D': swp(emptyTile[0]-1, emptyTile[1], emptyTile[0], emptyTile[1]);break;
        case 'L': swp(emptyTile[0], emptyTile[1]+1, emptyTile[0], emptyTile[1]);break;
        default:break;
      }
      if(debug) println(mv);
    }catch(ArrayIndexOutOfBoundsException e){
      if(debug) println("Error: "+e+"\nMove not permitted !");
    }
    if(debug) disp();
  }
  int h(int[] a, int[] b){//heuristic where b is the target and a the current position
  //Manhattan dist: Math.abs(a[0]-b[0])+Math.abs(a[1]-b[1]); (ideal for 4-way moves on grids)
  //Diagonal dist: h(n)=c*max(|n.x−goal.x| ,|n.y−goal.y|)
  // or more accurate: h(n)=sqrt(2)*Cn + Cn(max(|n.x−goal.x| ,|n.y−goal.y|)-min(|n.x−goal.x| ,|n.y−goal.y|)) where Cn is the cost of non-diag moves
    return (int) sqrt(pow(a[0]-b[0], 2)+pow(a[1]-b[1], 2));//Euclidian
  }
  int sH(){//total h(x, solvedX) for each tiles 
    int sh = 0;
    pzl solved = new pzl(nbTiles);
    solved.init();
    for(int i=0; i<tiles.length; i++){
      for(int j=0; j<tiles.length; j++){
        int[] c = {i, j};
        sh += h(c, lookfor(tiles[i][j], solved.tiles));
      }
    }
    return sh;
  }
  void solve(){
    if(!isSolved()){
      if(nbTiles<=9){//A*
        /*node(x, y){
          g(n)=g(n.parent)+cost(n.parent,n) where cost(n1, n2)=the movement cost from n1 to n2
          h(n): heuristic
          f(n)=g(n)+h(n) (total cost of the path via the current node)
        }*/
      }else{//IDA*
        
      }
    }
  }
  void swp(int ia, int ja, int ib, int jb){//swap
     int t=tiles[ia][ja];
     tiles[ia][ja] = tiles[ib][jb];
     tiles[ib][jb] = t;
  }
  int[] getState(){//get the 1D array of the 2D puzzle
    int state[] = new int[nbTiles], n=0;
    for(int i=0; i<tiles.length; i++){
      for(int j=0; j<tiles.length; j++) state[n++] = tiles[i][j];
    }
    return state;
  }
  boolean isSolved(){
    int[] state = getState();
    boolean is = (state[0]==1);
    int n = 2;
    for(int i=1; i<state.length-1; i++) is &= (state[i]==(n++));
    //tiles[(int)sqrt(nbTiles)-1][(int)sqrt(nbTiles)-1]
    return is;
  }
  boolean isTileSolved(int x, int y){
    boolean is = false;
    for(int i=1; i<nbTiles-1; i++){
      if(tiles[x][y]==i) is = true;
    }
    return is;
  }
  void scramble(boolean rdState){
    if(rdState){//random States
      int[] t = new int[nbTiles], state = new int[nbTiles];
      for(int i=0; i<t.length; i++) t[i] = i;
      for(int i=0; i<t.length; i++){
        int p = t[int(random(t.length))];
        state[i] = (p>=0)? p: t[int(random(t.length))];
        t = rm(t, state[i]);
      }
      fpa(t, 0);
      println("");
      
    }else{//random Moves
      char[] mvs = {'U', 'R', 'D', 'L'}, sc = new char[80];//20 for random states and 40 for random moves
      for(int i=0; i<sc.length; i++){
        char m=mvs[(int)random(mvs.length-1)];
        //anti-opposite/identical move filter
        if(i>0 && (sc[i-1]==m || sc[i-1]==mvs[(lkf(m, mvs)+2)%mvs.length])) m=mvs[(int)random(mvs.length-1)];
        if(i>0 && (sc[i-1]==m || sc[i-1]==mvs[(lkf(m, mvs)+2)%mvs.length])) m=mvs[(int)random(mvs.length-1)];
        if(i>0 && (sc[i-1]==m || sc[i-1]==mvs[(lkf(m, mvs)+2)%mvs.length])) m=mvs[(int)random(mvs.length-1)];
        
        pzl temp = new pzl(nbTiles);
        temp.init();
        boolean eq = true;
        
        for(int k=0; k<temp.tiles.length; k++){
          for(int j=0; j<temp.tiles[k].length; j++){
            if(tiles[k][j]!=temp.tiles[k][j]) eq = false;
          }
        }
        
        if(eq) m=mvs[(int)random(mvs.length-1)];
        
        sc[i] = m;
        move(m);
      }
    }
  }
  void zoom(short z){
    tileSize+=z;
    background(winBgClr);
    draw();
  }
  void incClr(float q){
      float ic = 63.75*q, r = red(tileClr), g = green(tileClr), b = blue(tileClr);
      b+=ic;
      if(b>=255){
        b=0;
        g+=ic;
      }
      if(g>=255){
        g=0;
        r+=ic;
      }
      tileClr = color(r, g, b);
  }
}

void swap(int a, int b){
  int t=a;
  a=b;
  b=t;
}

int[] lookfor(int x, int[][] mtx){//look for an element x in a matrix mtx
  int[] c = {-1, -1};
  for(int i=0; i<mtx.length; i++){
    for(int j=0; j<mtx[i].length; j++){
       c[0] = i;
       c[1] = j;
      if(mtx[i][j]==x) return c;//i is the row number and j the column which oppose j being the x-coord and i the y-coord
    }
  }
  return c;
}

int lkf(char x, char[] arr){//look for an element x in a matrix mtx
  for(int i=0; i<arr.length; i++){
      if(arr[i]==x) return i;//i is the row number and j the column which oppose j being the x-coord and i the y-coord
  }
  return -1;
}

void keyPressed(){
  if(key==CODED){
    if(keyCode==UP) Hpzl.move('U');
    else if(keyCode==RIGHT) Hpzl.move('R');
    else if(keyCode==DOWN) Hpzl.move('D');
    else if(keyCode==LEFT) Hpzl.move('L');
    else if(keyCode==ENTER) Hpzl.solve();
    if(timedMode && !Hpzl.isSolved() && (keyCode==UP || keyCode==RIGHT || keyCode==DOWN || keyCode==LEFT)) startTimer();
  }else if(key=='s' || keyCode==115) println("The statement: 'the 8-puzzle is solved' is "+Hpzl.isSolved());
  else if(key==' ' || keyCode==32) Hpzl.scramble(false);
  else if(key=='+' || keyCode==43) Hpzl.zoom((byte)5);
  else if(key=='-' || keyCode==45) Hpzl.zoom((byte)-5);
  else if(key=='>' || keyCode==62) Hpzl.incClr(255/128);
  else if(key=='<' || keyCode==60) Hpzl.incClr(255/128);
  else if(key=='i' || keyCode==105) Hpzl.init();//reset
}

void rgbCounter(float inc){//counts and loop through all the possible rgb colours mod inc
  if(inc<=0) inc=63.75;
  for(int r=0; r<257; r+=inc){
    for(int g=0; g<257; g+=inc){
      for(int b=0; b<257; b+=inc) println("rgb("+Math.round(r)+", "+Math.round(g)+", "+Math.round(b)+")");
    }
  }
}

void startTimer(){
  ms=millis();
  if(ms>=1000){
    ms=0;
    s++;
  }
  if(s>=60){
    s=0;
    min++;
  }
}

void printArr(int[] arr){
   println("");
   for(int i=0; i<arr.length; i++){
     if(i==0) print("Arr: "+arr[i]);
     else print(", "+arr[i]);
   }
}

int[] rm(int[] arr, int n){
   int[] res=new int[arr.length];
   for(int i=0; i<arr.length; i++){
     if(arr[i]==n) res[i] = -1;
     else res[i] = arr[i];
   }
   return res;
}

void fpa(int[] arr, int n){
   int[] fA = rm(arr, n);
   println("");
   for(int i=0; i<fA.length; i++){
     if(i==0 && fA[i]>0) print("Arr: "+fA[i]);
     else if(fA[i]>0) print(", "+fA[i]);
   }
}

int intLen(int n){
  int l = 0;
  while(Math.floor(n)!=0){
    n /= 10;
    l++;
  }
  return l; 
}

int[] splitInt(int n){
  int[] arr = new int[intLen(n)];
  for(int i=0; i<arr.length; i++){
    arr[i] = n/10;
    n /= 10;
  }
  return arr; 
}

int toInt(int[] n){
  int x = 0;
  for(int i=0; i<n.length; i++){
    x += n[i]*Math.pow(10, n.length-1-i);
  }
  return x;
}

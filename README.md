# Incremental TikZ Drawings in a Quarto Revealjs Presentation

This a first proof of concept!

- It works, but is currently a hack
- Should be implemented as a Filter or Plugin in Quarto / Revealjs at a later state

## Why?

I have a lot of TikZ drawings created in the past. I wanted to include some of 
them in a presentation, but TikZ in Quarto / Revealjs is only support by a r engine 
which converts the TikZ code into a graphics format like png or svg.

If you want to reveal parts of your drawing step by step during the presentation you 
have to create several versions of this graphics (preferable in svg to have scaling
ability). 

I hated this manual approach and I didn't want to modify my drawings. So I came up with this hack.

## Current approach supported by Quarto / Revealjs

### Using TikZ drawings in Quarto is possible by using the knitr engine for TikZ:

````         
``` {r}
#| cache = TRUE
#| echo = FALSE
#| engine = 'tikz'
#| fig.ext = 'svg'
#| engine.opts = list(dvisvgm.opts = "--font-format=woff"
#| template = "./tikz-preamble.tex")
#| fig-align: center
#| label: TikZ-Test-Label
#| file: "./tikz-test.tikz"
```
````

-   Placing TikZ code inside chunk instead of an external file is also possible
-   Engine options can also be given in the curly braces: {r, cache = TRUE, echo = FALSE, engine = 'tikz', ...}

**But: How to get an incremental drawing working?**

### Creating an incremental TikZ effect

See: <https://stackoverflow.com/questions/71760913/using-tikz-in-quarto-presentation>

-   Create a drawing for each incremental step and export it to a svg image
-   place a single image on a new slide for each incrementation step
-   mark the incrementation step slides titles with `## my-title {visibility="uncounted"}`

**Drawbacks:**

-   Manual process
    -   you need multiple versions of your TikZ drawing to generate the svg images
    -   or you have to edit the TikZ drawing multiple times
-   Same effort neccesary when there is an update of the drawing
-   Error prone

## My approach

  **Pros**

  - Graphics for the incremental steps are created automatically.
  - Original TikZ code is not really affected
      - Only some comments and a (otherwise automatically created) bounding box are added.
 
  **Cons**

  - It's quick an dirty hack - should be implemented as filter or plugin
  - You need to define a bounding box to have the image always at the same size during the steps

### Implementation

You can test the effect by yousrelf:

- download the files in this repository into a single folder 
- render the qmd file in RStudio or by issuing on command line: <br>
  `quarto preview incremental-tikz-test.qmd --to revealjs --presentation --no-watch-inputs --no-browse` 

#### Necessary steps

- Having only one complete TikZ drawing including all increments
- Insert start and end key tags into the TikZ drawing to mark the parts which have to be revealed
    - in my case: `% begin increment 1` and `% end increment 1`
    - example:

        ```
        % this one will be revealed on increment 1
        % begin increment number 1
          \node[draw=black, rectangle, above=of node0] (node1)
            {visible from increment 1};
          \draw[] (node0) -- (node1);
        % end increment number 1
       ```
- Define the normally automatically by Tex created bounding box to the largest area

    ```
    \useasboundingbox (0.3,0) rectangle (12.9,2.5);
    % Show bounding box for double checking
    % \draw [red] (current bounding box.south west) rectangle (current bounding box.north east);
    ```
    - By trial an error or
    - Drawing a grid with scale and axis over your drawing
    <br>
    
    ```
    % draw a grid with axis to read the dimensions of the necessary bounding box
    % remove all comment outs from the increments to view the full expanded canvas
    \draw[step=0.5cm,red,very thin] (0,0) grid (14,3.5);
    \draw[thick,->] (0,0) -- (14,0) node[anchor=north west] {x axis};
    \draw[thick,->] (0,0) -- (0,3.5) node[anchor=south east] {y axis};
    \foreach \x in {0,1,2,3,4,5,6,7,8,9,10,11,12,13}
       \draw (\x cm,1pt) -- (\x cm,-1pt) node[anchor=north] {$\x$};
    \foreach \y in {0,0.5,1,1.5,2.0,2.5,3.0}
       \draw (0.5pt,\y cm) -- (-0.5pt,\y cm) node[anchor=east] {$\y$};
    ``` 
- Use only a single slide with `{.r-stack}` and the `{.fragment}` features
- Create the incremental images on the fly by commenting out the hidden parts in the TikZ code with the help of a small bash script in a code chunk
  
  ```{bash}
  quarto_tikz_increments.sh -d "./" -f "./tikz-test.tikz" -i 1
  ```

  ``` 
  Syntax:
  quarto_tikz_increments [-h] [-d WORKING FOLDER] -f FILE -i INCREMENT NUMBER [-i INCREMENT NUMBER]
    -v: switch on Debug (should be first option!).
    -h: This help text!
    -d WORKING FOLDER: working directory - if not provided the current folder is used
    -f FILE: TIKZ file 
    -i INCREMENT NUMBER: one number is always required, option can be repeated multiple times;
                         if only one number is provided all increments up to that number are included.
  ```

- Example of Quarto code
  
  ````
  ---
  title: "Incremental TikZ drawings"
  author: "Günther Erhard"
  date: last-modified
  format: 
    revealjs:
      code-line-numbers: false
      theme: 
      - "./my-theme.scss"
  ---

  ## Test incremental TikZ drawings

  Just a first proof of concept for incremental display of TikZ drawings in Quarto revealjs presentations ...

  ::: {.r-stack}
  ```{bash}
  quarto_tikz_increments.sh -f "./tikz-test.tikz" -i 0
  ```

  ```{r, cache = TRUE, echo = FALSE, engine = 'tikz', fig.ext = 'svg', engine.opts = list(dvisvgm.opts = "--font-format=woff", template = "./tikz-preamble.tex")}
  #| fig-align: center
  #| label: TikZ-Test
  #| file: "./tikz-test-increments.tikz"
  ```

  :::: {.fragment}
  ```{bash}
  quarto_tikz_increments.sh -f "./tikz-test.tikz" -i 1
  ```

  ```{r, cache = TRUE, echo = FALSE, engine = 'tikz', fig.ext = 'svg', engine.opts = list(dvisvgm.opts = "--font-format=woff", template = "./tikz-preamble.tex")}
  #| fig-align: center
  #| label: TikZ-Test-1
  #| file: "./tikz-test-increments.tikz"
  ```
  ::::
  :::
  ````


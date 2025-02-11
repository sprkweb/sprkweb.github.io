---
title: "Image processing in Hugo"
date: 2021-06-22
lastmod: 2023-01-03
tags: [Hugo]
---

The [image processing system](https://gohugo.io/content-management/image-processing/)
in Hugo was an interesting discovery and I really liked it: it's quite powerful 
and functional, but it also has a simple interface that allows you to 
customize it with a few lines of code. It also supports 
[WebP](https://developers.google.com/speed/webp/), 
an image format that I also really like.
<!--more-->

I made the following shortcode for inserting images:

[layouts/shortcodes/img.html](https://github.com/sprkweb/sprkweb.github.io/blob/30b0c2f9f491b776cddc35f6b2afd139cb7a2790/layouts/shortcodes/img.html)

```html
{{ $original := $.Page.Resources.GetMatch (.Get 0) }}
{{ $optimized := $original.Fit "896x3072 webp" }}

<figure>
	<a href="{{ $original.RelPermalink }}" target="_blank">
		<picture>
			<source type="image/webp" srcset="{{ $optimized.RelPermalink }}">
			<img src="{{ $original.RelPermalink }}" alt="{{ .Get 1 }}"
				 width="{{ $optimized.Width }}" height="{{ $optimized.Height }}" />
		</picture>
	</a>
	<figcaption>{{ .Get 1 }}</figcaption>
</figure>
```

## Usage within Markdown

```code
{{</* img "myimage.png" "My favourite picture" */>}}
```

## What is it doing

1. The first argument is _the image from the page directory_
([Page Resource](https://gohugo.io/content-management/page-resources/))
2. If the image is wider than the specified value, _it's scaled_ to that width
with the proportions preserved: in my case it's a bit less than the maximum 
width of a text block on the page (896 pixels).
3. The optimized image is saved in the WebP format;
4. Since this size limit may not be enough for some images, 
the user can open the original in a new tab by clicking on the image;
5. The optimized image is shown on the page along with the caption 
from the second shortcode argument (for accessibility and cases when the image 
is not loaded);
6. For older browsers that do not support WebP and/or the picture tag, the original image is shown.

And -- most importantly -- all transformations are done at the building stage
automatically, which means that the directory with the content 
does not store two copies of the same picture in different formats, 
which is very convenient and consistent with the principle of DRY.

If you wish, you can similarly make several optimized images for different 
screen sizes using 
the [media attribute](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture#the_media_attribute) 
of the source tag.

## Settings

The default image quality is not the best, especially after they are scaled.

The following settings in the 
[config.yaml](https://github.com/sprkweb/sprkweb.github.io/blob/master/config.yaml)
file significantly improved the appearance of the optimized images:

```yaml
imaging:
  quality: 85 # percent
  hint: picture
  resampleFilter: Lanczos
```

In my case, the images are mostly screenshots, 
so for other cases (such as photos), the settings might need to be adjusted.

## The result

On [the test page](https://github.com/sprkweb/sprkweb.github.io/tree/7d40f7fa121bc34024a9562e6d52d8ac5f9ca0e9/content/projects/octava-page)
_without image scaling_, the size changed as follows:

Source format   | JPEG      | PNG
----------------|-----------|---------
Original size   | 15,95 Kb  | 21,33 Kb
WebP size       | 4,45 Kb   | 15,95 Kb

To me, the difference is barely noticeable when comparing side by side.
